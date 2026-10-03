@echo off
setlocal enabledelayedexpansion
title Levantar proyecto - Actividad API + App Movil

set "ROOT=%~dp0"
set "BACKEND_DIR=%ROOT%Actividad_API_BACKEND"
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
set "CURL=%SystemRoot%\System32\curl.exe"

echo ============================================
echo   Levantando el proyecto para la demo
echo ============================================
echo.

REM Verificar Docker Desktop
echo [1/5] Verificando Docker Desktop...
docker version >nul 2>&1
if not errorlevel 1 goto docker_ready

echo Docker no responde, intentando arrancarlo...
if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
) else (
    echo No se encontro Docker Desktop instalado en la ruta esperada.
    echo Abrelo manualmente y vuelve a correr este script.
    pause
    exit /b 1
)

echo Esperando a que Docker arranque (puede tardar 1-2 minutos)...
set /a intentos=0
:esperar_docker
ping -n 6 127.0.0.1 >nul
docker version >nul 2>&1
if not errorlevel 1 goto docker_ready
set /a intentos+=1
if !intentos! geq 24 (
    echo Docker no arranco a tiempo. Abrelo manualmente y vuelve a intentar.
    pause
    exit /b 1
)
goto esperar_docker

:docker_ready
echo Docker esta listo.
echo.

REM Bajar instancia previa
echo [2/5] Deteniendo una instancia previa del proyecto (si existia)...
pushd "%BACKEND_DIR%"
docker compose down >nul 2>&1
popd
echo.

REM Levantar el proyecto
echo [3/5] Levantando API + Base de datos con Docker Compose...
pushd "%BACKEND_DIR%"
docker compose up --build -d
set "COMPOSE_RESULT=%errorlevel%"
popd

if "%COMPOSE_RESULT%"=="0" goto verificar_puerto

echo El arranque fallo, puede que otro proceso este usando el puerto 8080 o 5432.
echo Liberando esos puertos...
call :liberar_puerto 8080
call :liberar_puerto 5432

echo Reintentando levantar el proyecto...
pushd "%BACKEND_DIR%"
docker compose up --build -d
set "COMPOSE_RESULT=%errorlevel%"
popd

if not "%COMPOSE_RESULT%"=="0" (
    echo No se pudo levantar el proyecto. Revisa el mensaje de error de arriba.
    pause
    exit /b 1
)

:verificar_puerto
echo.

REM Esperar a que la API responda
echo [4/5] Esperando a que la API responda en el puerto 8080...
set /a intentos=0
:esperar_api
"%CURL%" -s -o nul http://localhost:8080/api/auth/login <nul
if not errorlevel 1 goto api_lista
ping -n 4 127.0.0.1 >nul
set /a intentos+=1
if !intentos! geq 30 (
    echo La API no respondio a tiempo. Revisa los logs con:
    echo   docker compose -f "%BACKEND_DIR%\docker-compose.yml" logs api
    pause
    exit /b 1
)
goto esperar_api

:api_lista
echo La API esta lista en http://localhost:8080
echo.

REM Reconectar adb reverse si hay un celular por USB
echo [5/5] Buscando un dispositivo Android conectado por USB...
if not exist "%ADB%" (
    echo No se encontro adb, se omite este paso.
    goto fin
)

for /f "skip=1 tokens=1,2" %%A in ('"%ADB%" devices') do (
    if "%%B"=="device" (
        echo Dispositivo encontrado: %%A
        "%ADB%" reverse tcp:8080 tcp:8080
        echo Tunel USB listo. La app puede usar http://localhost:8080 sin importar la red.
        goto fin
    )
)
echo No hay ningun dispositivo Android autorizado por USB en este momento.

:fin
echo.
echo ============================================
echo   Proyecto listo para mostrar
echo   Backend:  http://localhost:8080
echo ============================================
pause
exit /b 0

REM Funciones
:liberar_puerto
set "PUERTO=%~1"
set "PIDS_VISTOS=;"
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%PUERTO% .*LISTENING"') do (
    echo !PIDS_VISTOS! | findstr /C:";%%P;" >nul
    if errorlevel 1 (
        set "PIDS_VISTOS=!PIDS_VISTOS!%%P;"
        call :matar_si_no_es_docker %%P
    )
)
exit /b 0

:matar_si_no_es_docker
set "PID=%~1"
if "%PID%"=="" exit /b 0
set "NOMBRE="
for /f "tokens=1" %%N in ('tasklist /FI "PID eq %PID%" /NH 2^>nul') do set "NOMBRE=%%N"

echo %NOMBRE% | findstr /I "docker vpnkit com.docker wsl" >nul
if not errorlevel 1 (
    echo   PID %PID% ^(%NOMBRE%^) pertenece a Docker/WSL, no se toca.
    exit /b 0
)

echo   Cerrando proceso %NOMBRE% ^(PID %PID%^) que ocupaba el puerto %PUERTO%...
taskkill /F /PID %PID% >nul 2>&1
exit /b 0
