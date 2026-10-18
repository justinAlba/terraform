<#
.SYNOPSIS
  Ejecuta las actividades de la asignacion de pruebas de carga.

.EXAMPLE
  .\pruebas.ps1 linea-base      # Actividad 1: 10 VUs, 1 min
  .\pruebas.ps1 progresivo      # Actividad 2: 50/100/250/500 VUs, 2 min cada uno
  .\pruebas.ps1 estres          # Actividad 4: sube hasta el punto de degradacion
  .\pruebas.ps1 estres -Niveles '20,30,40,50'   # niveles personalizados
  .\pruebas.ps1 recuperacion    # Actividad 5: carga alta, corte y vaciado de SQS
  .\pruebas.ps1 humo            # 2 VUs, 15 s: verifica que todo responde

  Cada prueba deja sus resultados en results/<nombre>/ (resumen de k6, serie de
  tiempo y ventana.json con la hora UTC de inicio/fin para consultar CloudWatch).
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('humo', 'linea-base', 'progresivo', 'estres', 'recuperacion')]
    [string]$Actividad,

    # VUs de la carga alta de la Actividad 5. Por defecto: el ultimo nivel estable
    # de la prueba de estres (leido de results/estres-resultado.json).
    [int]$VusRecuperacion = 0,

    [int]$PausaEntreEscenarios = 90,

    # Actividad 4: niveles de VUs separados por coma (default: los de la asignacion).
    [string]$Niveles = '100,250,500,750,1000,1500,2000'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force 'results' | Out-Null

# ---------------------------------------------------------------- Recursos AWS
$Prefijo = 'actividad-api-prod'
$LambdaApi = "$Prefijo-api"
$LambdaNotif = 'notification-lambda'
$ColaSqs = "$Prefijo-notifications"

function Get-UtcAhora { (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }

if (-not $env:API_URL) {
    $env:API_URL = aws apigatewayv2 get-apis --query "Items[?Name=='$Prefijo-http-api'].ApiEndpoint | [0]" --output text
    if (-not $env:API_URL -or $env:API_URL -eq 'None') { throw 'No se encontro la API en AWS. Define $env:API_URL manualmente.' }
}
$ColaUrl = aws sqs get-queue-url --queue-name $ColaSqs --query QueueUrl --output text
Write-Host "API_URL = $env:API_URL" -ForegroundColor Cyan

# ---------------------------------------------------------------- Utilidades
function Invoke-Prueba {
    param([string]$Nombre, [int]$Vus, [string]$Duracion, [string]$Rampa = '0s', [switch]$Abortar)

    $dir = "results/$Nombre"
    New-Item -ItemType Directory -Force $dir | Out-Null
    Write-Host "`n=== $Nombre : $Vus VUs durante $Duracion (rampa $Rampa) ===" -ForegroundColor Yellow

    $inicio = Get-UtcAhora
    # k6 escribe sus avisos en stderr; con 'Stop', PowerShell 5.1 los trataria como error fatal.
    $ErrorActionPreference = 'Continue'
    k6 run `
        -e API_URL=$env:API_URL -e NOMBRE=$Nombre -e VUS=$Vus -e DURACION=$Duracion `
        -e RAMPA=$Rampa -e ABORTAR=$($Abortar.IsPresent.ToString().ToLower()) `
        --out "csv=$dir/serie.csv.gz" `
        carga.js 2>&1 | ForEach-Object { "$_" } | Write-Host
    $codigo = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $fin = Get-UtcAhora

    @{ nombre = $Nombre; vus = $Vus; duracion = $Duracion; inicio_utc = $inicio; fin_utc = $fin; codigo_salida_k6 = $codigo } |
        ConvertTo-Json | Set-Content -Encoding utf8 "$dir/ventana.json"
    return $codigo
}

function Get-SumaMetrica {
    param([string]$Namespace, [string]$Metrica, [string]$Dimension, [string]$Valor, [string]$Inicio, [string]$Fin, [string]$Estadistica = 'Sum')
    $r = aws cloudwatch get-metric-statistics --namespace $Namespace --metric-name $Metrica `
        --dimensions "Name=$Dimension,Value=$Valor" --start-time $Inicio --end-time $Fin `
        --period 60 --statistics $Estadistica --query "Datapoints[].$Estadistica" --output json | ConvertFrom-Json
    if (-not $r) { return 0 }
    if ($Estadistica -eq 'Maximum') { return ($r | Measure-Object -Maximum).Maximum }
    return ($r | Measure-Object -Sum).Sum
}

function Get-EstadoCola {
    $a = aws sqs get-queue-attributes --queue-url $ColaUrl `
        --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible `
        --query Attributes --output json | ConvertFrom-Json
    [pscustomobject]@{
        visibles   = [int]$a.ApproximateNumberOfMessages
        en_proceso = [int]$a.ApproximateNumberOfMessagesNotVisible
    }
}

function Wait-ColaVacia {
    # Registra cada 15 s el estado de la cola hasta que queda vacia (Actividad 5).
    param([string]$Archivo, [int]$MaxMinutos = 60)
    "hora_utc,segundos,visibles,en_proceso" | Set-Content -Encoding utf8 $Archivo
    $t0 = Get-Date
    while ($true) {
        $c = Get-EstadoCola
        $seg = [int]((Get-Date) - $t0).TotalSeconds
        "$(Get-UtcAhora),$seg,$($c.visibles),$($c.en_proceso)" | Add-Content -Encoding utf8 $Archivo
        Write-Host ("  t={0,5}s  visibles={1,7}  en_proceso={2,5}" -f $seg, $c.visibles, $c.en_proceso)
        if ($c.visibles -eq 0 -and $c.en_proceso -eq 0) { return $seg }
        if ($seg -gt $MaxMinutos * 60) { Write-Warning "La cola no se vacio en $MaxMinutos min"; return -1 }
        Start-Sleep -Seconds 15
    }
}

# ---------------------------------------------------------------- Actividades
switch ($Actividad) {
    'humo' {
        Invoke-Prueba -Nombre '00-humo' -Vus 2 -Duracion '15s' | Out-Null
    }

    'linea-base' {
        Invoke-Prueba -Nombre '01-linea-base' -Vus 10 -Duracion '1m' | Out-Null
    }

    'progresivo' {
        foreach ($vus in 50, 100, 250, 500) {
            Invoke-Prueba -Nombre "02-progresivo-$vus" -Vus $vus -Duracion '2m' | Out-Null
            Write-Host "Pausa de $PausaEntreEscenarios s para que el sistema se estabilice..."
            Start-Sleep -Seconds $PausaEntreEscenarios
        }
    }

    'estres' {
        $niveles = $Niveles -split ',' | ForEach-Object { [int]$_.Trim() }
        # Si quedan mensajes de una prueba anterior, el criterio de SQS se dispararia en falso.
        $c = Get-EstadoCola
        if ($c.visibles + $c.en_proceso -gt 0) {
            Write-Host 'La cola no esta vacia; se espera a que se vacie antes de empezar.'
            Wait-ColaVacia -Archivo 'results/04-pre-vaciado.csv' | Out-Null
        }
        $ultimoEstable = 0
        $motivo = 'Se completaron todos los niveles sin degradacion'
        foreach ($vus in $niveles) {
            $nombre = "04-estres-$vus"
            $codigo = Invoke-Prueba -Nombre $nombre -Vus $vus -Duracion '2m' -Rampa '30s' -Abortar

            # CloudWatch publica con ~1-2 min de retraso.
            Write-Host 'Esperando 120 s a que CloudWatch publique las metricas...'
            Start-Sleep -Seconds 120
            $v = Get-Content "results/$nombre/ventana.json" | ConvertFrom-Json
            $m = Get-Content "results/$nombre/metricas.json" | ConvertFrom-Json

            $throttles = (Get-SumaMetrica 'AWS/Lambda' 'Throttles' 'FunctionName' $LambdaApi $v.inicio_utc (Get-UtcAhora)) +
                         (Get-SumaMetrica 'AWS/Lambda' 'Throttles' 'FunctionName' $LambdaNotif $v.inicio_utc (Get-UtcAhora))
            $edadCola = Get-SumaMetrica 'AWS/SQS' 'ApproximateAgeOfOldestMessage' 'QueueName' $ColaSqs $v.inicio_utc (Get-UtcAhora) 'Maximum'
            $cola = Get-EstadoCola

            $chequeo = [ordered]@{
                vus                    = $vus
                tasa_errores           = $m.tasa_errores
                p95_ms                 = $m.latencia_ms.p95
                throttles_lambda       = $throttles
                edad_max_mensaje_sqs_s = $edadCola
                mensajes_en_cola       = $cola.visibles
                k6_abortado            = ($codigo -eq 99)
            }
            $chequeo | ConvertTo-Json | Set-Content -Encoding utf8 "results/$nombre/criterios.json"
            $chequeo | Format-Table | Out-String | Write-Host

            $motivos = @()
            if ($codigo -eq 99) { $motivos += 'k6 aborto por threshold (errores > 5% o p95 > 5 s)' }
            if ($m.tasa_errores -gt 0.05) { $motivos += "errores $([math]::Round($m.tasa_errores * 100, 2))% > 5%" }
            if ($m.latencia_ms.p95 -gt 5000) { $motivos += "p95 $([math]::Round($m.latencia_ms.p95)) ms > 5 s" }
            if ($throttles -gt 0) { $motivos += "throttling en Lambda ($throttles)" }
            # Saturacion de SQS: mensajes esperando mas de 5 minutos para ser procesados.
            if ($edadCola -gt 300) { $motivos += "SQS saturada (mensaje mas antiguo: $edadCola s)" }

            if ($motivos.Count -gt 0) {
                $motivo = "Degradacion en $vus VUs: " + ($motivos -join '; ')
                Write-Host $motivo -ForegroundColor Red
                break
            }
            $ultimoEstable = $vus
            Write-Host "Nivel $vus VUs estable." -ForegroundColor Green
            if ($cola.visibles -gt 0) {
                Write-Host 'Vaciando la cola antes del siguiente nivel...'
                Wait-ColaVacia -Archivo "results/$nombre/vaciado-cola.csv" | Out-Null
            }
        }
        @{ ultimo_nivel_estable = $ultimoEstable; motivo_parada = $motivo } |
            ConvertTo-Json | Set-Content -Encoding utf8 'results/estres-resultado.json'
    }

    'recuperacion' {
        if ($VusRecuperacion -le 0) {
            $VusRecuperacion = 500
            if (Test-Path 'results/estres-resultado.json') {
                $e = Get-Content 'results/estres-resultado.json' | ConvertFrom-Json
                if ($e.ultimo_nivel_estable -gt 0) { $VusRecuperacion = $e.ultimo_nivel_estable }
            }
        }
        $c = Get-EstadoCola
        if ($c.visibles + $c.en_proceso -gt 0) {
            Write-Host 'La cola no esta vacia; se espera a que se vacie antes de empezar.'
            Wait-ColaVacia -Archivo 'results/05-pre-vaciado.csv' | Out-Null
        }

        Invoke-Prueba -Nombre '05-recuperacion' -Vus $VusRecuperacion -Duracion '3m' -Rampa '30s' | Out-Null
        $corte = Get-UtcAhora
        Write-Host "`nCarga detenida a las $corte UTC. Midiendo el vaciado de SQS..." -ForegroundColor Yellow
        $segundos = Wait-ColaVacia -Archivo 'results/05-recuperacion/vaciado-cola.csv'

        # Se deja correr 5 min mas para ver en CloudWatch como bajan las Lambdas a 0.
        Write-Host 'Cola vacia. Esperando 5 min para observar la recuperacion de las Lambdas...'
        Start-Sleep -Seconds 300
        @{ vus = $VusRecuperacion; corte_carga_utc = $corte; segundos_vaciado_sqs = $segundos; fin_observacion_utc = (Get-UtcAhora) } |
            ConvertTo-Json | Set-Content -Encoding utf8 'results/05-recuperacion/recuperacion.json'
        Write-Host "SQS tardo $segundos s en vaciarse." -ForegroundColor Green
    }
}
