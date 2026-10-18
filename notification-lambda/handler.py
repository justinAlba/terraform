"""notification-lambda

Consume la cola SQS suscrita al topic SNS de notificaciones y envia cada
mensaje como correo con Amazon SES. Todo lo que pasa queda en CloudWatch Logs.

Flujo: API (Spring Boot) -> SNS -> SQS -> esta Lambda -> SES -> correo.
"""

import json
import logging
import os
import time
import uuid

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SENDER_EMAIL = os.environ["SENDER_EMAIL"]

# Pruebas de carga: los destinatarios de LOAD_TEST_DOMAIN no se envian por SES
# (sandbox: ~1 correo/s y solo destinatarios verificados). Se simula la latencia
# de SES para que el resto del flujo SNS -> SQS -> Lambda se mida igual.
LOAD_TEST_MODE = os.environ.get("LOAD_TEST_MODE", "false").lower() == "true"
LOAD_TEST_DOMAIN = os.environ.get("LOAD_TEST_DOMAIN", "@test.com").lower()
SIMULATED_SES_MS = int(os.environ.get("SIMULATED_SES_MS", "100"))

ses = boto3.client("sesv2")


class MensajeInvalido(ValueError):
    pass


def handler(event, context):
    records = event.get("Records", [])
    logger.info("Lote recibido desde SQS: %d mensaje(s)", len(records))

    # Solo se reintentan los mensajes que fallaron; tras varios intentos SQS
    # los mueve a la cola de mensajes muertos (DLQ).
    fallidos = []

    for record in records:
        sqs_message_id = record["messageId"]
        try:
            notificacion, sns_message_id = extraer_notificacion(record)
            logger.info(
                "Procesando sqsMessageId=%s snsMessageId=%s para=%s asunto=%r solicitadoPor=%s",
                sqs_message_id,
                sns_message_id,
                notificacion["email"],
                notificacion["subject"],
                notificacion.get("requestedBy"),
            )
            ses_message_id = enviar_correo(notificacion)
            logger.info(
                "Correo enviado sqsMessageId=%s sesMessageId=%s para=%s",
                sqs_message_id,
                ses_message_id,
                notificacion["email"],
            )
        except Exception:
            logger.exception("Error procesando sqsMessageId=%s", sqs_message_id)
            fallidos.append({"itemIdentifier": sqs_message_id})

    logger.info("Lote terminado: %d ok, %d con error", len(records) - len(fallidos), len(fallidos))
    return {"batchItemFailures": fallidos}


def extraer_notificacion(record):
    """El cuerpo del mensaje SQS es el sobre JSON de SNS; la notificacion va en "Message"."""
    try:
        cuerpo = json.loads(record["body"])
        if cuerpo.get("Type") == "Notification":
            sns_message_id = cuerpo.get("MessageId")
            notificacion = json.loads(cuerpo["Message"])
        else:
            sns_message_id = None
            notificacion = cuerpo
    except (KeyError, TypeError, json.JSONDecodeError) as ex:
        raise MensajeInvalido(f"Cuerpo del mensaje no es JSON valido: {ex}") from ex

    faltantes = [campo for campo in ("email", "subject", "message") if not notificacion.get(campo)]
    if faltantes:
        raise MensajeInvalido(f"Faltan campos obligatorios: {', '.join(faltantes)}")

    return notificacion, sns_message_id


def enviar_correo(notificacion):
    if LOAD_TEST_MODE and notificacion["email"].lower().endswith(LOAD_TEST_DOMAIN):
        time.sleep(SIMULATED_SES_MS / 1000)
        return f"simulado-{uuid.uuid4()}"

    respuesta = ses.send_email(
        FromEmailAddress=SENDER_EMAIL,
        Destination={"ToAddresses": [notificacion["email"]]},
        Content={
            "Simple": {
                "Subject": {"Data": notificacion["subject"], "Charset": "UTF-8"},
                "Body": {"Text": {"Data": notificacion["message"], "Charset": "UTF-8"}},
            }
        },
    )
    return respuesta["MessageId"]
