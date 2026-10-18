
project_name    = "actividad-api"
environment     = "prod"
lambda_zip_path = "../Actividad_API_BACKEND/target/api-lambda.zip"

lambda_memory_mb       = 2048
lambda_timeout_seconds = 30
snapstart_enabled      = true
log_retention_days     = 7
jwt_expiration_ms      = 3600000

cors_allow_origins = ["*"]

# Notificaciones (SNS -> SQS -> Lambda -> SES). El remitente llega desde el
# secret NOTIFICATION_SENDER_EMAIL (TF_VAR_notification_sender_email).
notification_lambda_name            = "notification-lambda"
notification_lambda_timeout_seconds = 30
# En el sandbox de SES el destinatario tambien debe estar verificado:
# agrega aqui los correos de prueba (cada uno recibe un enlace de verificacion).
notification_test_recipients = [
  "jeremyvargas24.jrvu@gmail.com",
]

