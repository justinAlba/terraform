"""Descarga de CloudWatch las metricas, imagenes y consultas de logs de cada prueba.

Uso (desde load-tests/):
    python scripts/cloudwatch.py

Para cada carpeta results/<escenario>/ con ventana.json genera:
    results/<escenario>/cloudwatch.json   series por minuto y agregados (Actividad 3)
Para cada actividad (01, 02, 04, 05) genera:
    evidencias/<actividad>/*.png          graficas de CloudWatch por servicio
    evidencias/<actividad>/logs.json      resultados de CloudWatch Logs Insights
"""

import json
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

import boto3

REGION = "us-east-1"
PREFIJO = "actividad-api-prod"
LAMBDA_API = f"{PREFIJO}-api"
LAMBDA_NOTIF = "notification-lambda"
COLA = f"{PREFIJO}-notifications"
DLQ = f"{PREFIJO}-notifications-dlq"
TOPIC = f"{PREFIJO}-notifications"
LOG_API_GW = f"/aws/apigateway/{PREFIJO}"
LOG_LAMBDA_API = f"/aws/lambda/{LAMBDA_API}"
LOG_NOTIF = f"/aws/lambda/{LAMBDA_NOTIF}"

RAIZ = Path(__file__).resolve().parent.parent
RESULTADOS = RAIZ / "results"
EVIDENCIAS = RAIZ / "evidencias"

cw = boto3.client("cloudwatch", region_name=REGION)
logs = boto3.client("logs", region_name=REGION)
apigw = boto3.client("apigatewayv2", region_name=REGION)

API_ID = next(a["ApiId"] for a in apigw.get_apis()["Items"] if a["Name"] == f"{PREFIJO}-http-api")
GW = ["ApiId", API_ID, "Stage", "$default"]

# (id, namespace, metrica, dimensiones, estadistica, etiqueta)
METRICAS = [
    ("gw_count", "AWS/ApiGateway", "Count", GW, "Sum", "API Gateway - Request Count"),
    ("gw_latency", "AWS/ApiGateway", "Latency", GW, "Average", "API Gateway - Latency avg (ms)"),
    ("gw_latency_p95", "AWS/ApiGateway", "Latency", GW, "p95", "API Gateway - Latency p95 (ms)"),
    ("gw_integration", "AWS/ApiGateway", "IntegrationLatency", GW, "Average", "API Gateway - Integration Latency avg (ms)"),
    ("gw_4xx", "AWS/ApiGateway", "4xx", GW, "Sum", "API Gateway - 4XX"),
    ("gw_5xx", "AWS/ApiGateway", "5xx", GW, "Sum", "API Gateway - 5XX"),
    ("api_invocations", "AWS/Lambda", "Invocations", ["FunctionName", LAMBDA_API], "Sum", "Lambda API - Invocations"),
    ("api_duration", "AWS/Lambda", "Duration", ["FunctionName", LAMBDA_API], "Average", "Lambda API - Duration avg (ms)"),
    ("api_duration_max", "AWS/Lambda", "Duration", ["FunctionName", LAMBDA_API], "Maximum", "Lambda API - Duration max (ms)"),
    ("api_errors", "AWS/Lambda", "Errors", ["FunctionName", LAMBDA_API], "Sum", "Lambda API - Errors"),
    ("api_throttles", "AWS/Lambda", "Throttles", ["FunctionName", LAMBDA_API], "Sum", "Lambda API - Throttles"),
    ("api_concurrency", "AWS/Lambda", "ConcurrentExecutions", ["FunctionName", LAMBDA_API], "Maximum", "Lambda API - Concurrent Executions"),
    ("sns_published", "AWS/SNS", "NumberOfMessagesPublished", ["TopicName", TOPIC], "Sum", "SNS - NumberOfMessagesPublished"),
    ("sns_delivered", "AWS/SNS", "NumberOfNotificationsDelivered", ["TopicName", TOPIC], "Sum", "SNS - NumberOfNotificationsDelivered"),
    ("sns_failed", "AWS/SNS", "NumberOfNotificationsFailed", ["TopicName", TOPIC], "Sum", "SNS - NumberOfNotificationsFailed"),
    ("sqs_sent", "AWS/SQS", "NumberOfMessagesSent", ["QueueName", COLA], "Sum", "SQS - NumberOfMessagesSent"),
    ("sqs_deleted", "AWS/SQS", "NumberOfMessagesDeleted", ["QueueName", COLA], "Sum", "SQS - NumberOfMessagesDeleted"),
    ("sqs_visible", "AWS/SQS", "ApproximateNumberOfMessagesVisible", ["QueueName", COLA], "Maximum", "SQS - ApproximateNumberOfMessagesVisible"),
    ("sqs_age", "AWS/SQS", "ApproximateAgeOfOldestMessage", ["QueueName", COLA], "Maximum", "SQS - ApproximateAgeOfOldestMessage (s)"),
    ("dlq_visible", "AWS/SQS", "ApproximateNumberOfMessagesVisible", ["QueueName", DLQ], "Maximum", "DLQ - mensajes"),
    ("notif_concurrency", "AWS/Lambda", "ConcurrentExecutions", ["FunctionName", LAMBDA_NOTIF], "Maximum", "Notification Lambda - Concurrent Executions"),
    ("notif_invocations", "AWS/Lambda", "Invocations", ["FunctionName", LAMBDA_NOTIF], "Sum", "Notification Lambda - Invocations"),
    ("notif_duration", "AWS/Lambda", "Duration", ["FunctionName", LAMBDA_NOTIF], "Average", "Notification Lambda - Duration avg (ms)"),
    ("notif_errors", "AWS/Lambda", "Errors", ["FunctionName", LAMBDA_NOTIF], "Sum", "Notification Lambda - Errors"),
    ("notif_throttles", "AWS/Lambda", "Throttles", ["FunctionName", LAMBDA_NOTIF], "Sum", "Notification Lambda - Throttles"),
]

ACTIVIDADES = {
    "01": "Actividad 1 - Linea base",
    "02": "Actividad 2 - Incremento progresivo",
    "04": "Actividad 4 - Estres",
    "05": "Actividad 5 - Recuperacion",
}


def iso(t):
    return datetime.fromisoformat(t.replace("Z", "+00:00"))


def dims(lista):
    return [{"Name": lista[i], "Value": lista[i + 1]} for i in range(0, len(lista), 2)]


def descargar_metricas(inicio, fin):
    consultas = [
        {
            "Id": mid,
            "Label": etiqueta,
            "MetricStat": {
                "Metric": {"Namespace": ns, "MetricName": nombre, "Dimensions": dims(d)},
                "Period": 60,
                "Stat": stat,
            },
        }
        for mid, ns, nombre, d, stat, etiqueta in METRICAS
    ]
    r = cw.get_metric_data(MetricDataQueries=consultas, StartTime=inicio, EndTime=fin, ScanBy="TimestampAscending")
    estadistica = {m[0]: m[4] for m in METRICAS}
    salida = {}
    for res in r["MetricDataResults"]:
        valores = res["Values"]
        stat = estadistica[res["Id"]]
        if not valores:
            total = 0
        elif stat == "Sum":
            total = sum(valores)
        elif stat in ("Maximum", "p95"):
            total = max(valores)
        else:
            total = sum(valores) / len(valores)
        salida[res["Id"]] = {
            "etiqueta": res["Label"],
            "estadistica": stat,
            "agregado": total,
            "serie": [[t.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), v] for t, v in zip(res["Timestamps"], valores)],
        }
    return salida


WIDGETS = {
    "api-gateway": ("API Gateway", ["gw_count", "gw_latency", "gw_integration", "gw_4xx", "gw_5xx"]),
    "lambda-api": ("Lambda principal", ["api_invocations", "api_duration", "api_errors", "api_throttles", "api_concurrency"]),
    "sns": ("SNS", ["sns_published", "sns_delivered", "sns_failed"]),
    "sqs": ("SQS", ["sqs_sent", "sqs_deleted", "sqs_visible"]),
    "sqs-edad": ("SQS - edad del mensaje mas antiguo y DLQ", ["sqs_age", "dlq_visible"]),
    "notification-lambda": ("Notification Lambda", ["notif_concurrency", "notif_invocations", "notif_errors", "notif_throttles"]),
    "notification-lambda-duracion": ("Notification Lambda - Duration", ["notif_duration"]),
    "lambdas-concurrencia": ("Lambdas - Concurrent Executions (limite de la cuenta: 10)", ["api_concurrency", "notif_concurrency"]),
    "lambdas-throttles": ("Lambdas - Throttles", ["api_throttles", "notif_throttles"]),
    "lambda-api-latencia": ("API Gateway / Lambda - latencias (ms)", ["gw_latency", "gw_latency_p95", "gw_integration", "api_duration"]),
}


def imagen_widget(titulo, ids, inicio, fin, destino):
    por_id = {m[0]: m for m in METRICAS}
    metricas = []
    for mid in ids:
        _, ns, nombre, d, stat, etiqueta = por_id[mid]
        metricas.append([ns, nombre, *d, {"stat": stat, "label": etiqueta}])
    widget = {
        "title": titulo,
        "metrics": metricas,
        "view": "timeSeries",
        "stacked": False,
        "region": REGION,
        "period": 60,
        "start": inicio.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "end": fin.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "width": 1200,
        "height": 500,
        "legend": {"position": "bottom"},
    }
    png = cw.get_metric_widget_image(MetricWidget=json.dumps(widget), OutputFormat="png")["MetricWidgetImage"]
    destino.write_bytes(png)


CONSULTAS_LOGS = {
    "api_gateway_status": (
        [LOG_API_GW],
        "stats count(*) as requests, avg(integrationLatency) as integracion_avg_ms, "
        "max(integrationLatency) as integracion_max_ms by status | sort requests desc",
    ),
    "lambda_api_report": (
        [LOG_LAMBDA_API],
        'filter @type = "REPORT" | stats count(*) as invocaciones, avg(@duration) as duracion_avg_ms, '
        "pct(@duration, 95) as duracion_p95_ms, max(@duration) as duracion_max_ms, "
        "max(@maxMemoryUsed / 1000 / 1000) as memoria_max_mb, count(@initDuration) as cold_starts",
    ),
    "lambda_api_errores": (
        [LOG_LAMBDA_API],
        "filter @message like /(?i)(exception|error)/ and @message not like /REPORT/ "
        "| stats count(*) as ocurrencias by substr(@message, 0, 120) as mensaje | sort ocurrencias desc | limit 10",
    ),
    "notification_lotes": (
        [LOG_NOTIF],
        'filter message like "Lote terminado" | parse message "Lote terminado: * ok, * con error" as ok, fallidos '
        "| stats count(*) as lotes, sum(ok) as mensajes_ok, sum(fallidos) as mensajes_error, avg(ok + fallidos) as tamano_lote_avg",
    ),
    "notification_errores": (
        [LOG_NOTIF],
        'filter level = "ERROR" | stats count(*) as errores by substr(message, 0, 120) as mensaje | sort errores desc | limit 10',
    ),
}


def consultar_logs(inicio, fin):
    salida = {}
    for nombre, (grupos, query) in CONSULTAS_LOGS.items():
        qid = logs.start_query(
            logGroupNames=grupos, startTime=int(inicio.timestamp()), endTime=int(fin.timestamp()), queryString=query
        )["queryId"]
        while True:
            r = logs.get_query_results(queryId=qid)
            if r["status"] in ("Complete", "Failed", "Cancelled", "Timeout"):
                break
            time.sleep(2)
        salida[nombre] = {
            "query": query,
            "estado": r["status"],
            "filas": [{c["field"]: c["value"] for c in fila} for fila in r["results"]],
        }
    return salida


def main():
    ventanas = {}
    for f in sorted(RESULTADOS.glob("*/ventana.json")):
        v = json.loads(f.read_text(encoding="utf-8-sig"))
        v["nombre"] = f.parent.name
        # 00-humo y la corrida desde el PC local (red inestable) no entran al informe.
        if v["nombre"].endswith("pc-local") or v["nombre"].startswith("00"):
            continue
        inicio, fin = iso(v["inicio_utc"]), iso(v["fin_utc"])
        rec = f.parent / "recuperacion.json"
        if rec.exists():
            fin = iso(json.loads(rec.read_text(encoding="utf-8-sig"))["fin_observacion_utc"])
        ventanas[v["nombre"]] = (inicio, fin)

        print(f"Metricas: {v['nombre']}")
        # Minutos completos que cubren la prueba; mas margen mezclaria el escenario siguiente.
        datos = descargar_metricas(inicio.replace(second=0), fin.replace(second=0) + timedelta(minutes=1))
        (f.parent / "cloudwatch.json").write_text(json.dumps(datos, indent=2), encoding="utf-8")

    for prefijo, titulo in ACTIVIDADES.items():
        grupo = [w for n, w in ventanas.items() if n.startswith(prefijo)]
        if not grupo:
            continue
        inicio = min(w[0] for w in grupo) - timedelta(minutes=2)
        fin = max(w[1] for w in grupo) + timedelta(minutes=2)
        fin = min(fin, datetime.now(timezone.utc))
        carpeta = EVIDENCIAS / f"{prefijo}-{titulo.split(' - ')[1].lower().replace(' ', '-')}"
        carpeta.mkdir(parents=True, exist_ok=True)
        print(f"Evidencias: {titulo} ({inicio:%H:%M} - {fin:%H:%M} UTC)")
        for archivo, (nombre_widget, ids) in WIDGETS.items():
            imagen_widget(f"{nombre_widget} | {titulo}", ids, inicio, fin, carpeta / f"{archivo}.png")
        # Los logs tienen marca de tiempo exacta: se consultan sin margen para no mezclar actividades.
        exacto = (min(w[0] for w in grupo), max(w[1] for w in grupo))
        (carpeta / "logs.json").write_text(json.dumps(consultar_logs(*exacto), indent=2, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
