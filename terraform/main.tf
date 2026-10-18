data "aws_caller_identity" "current" {}

locals {
  name       = "${var.project_name}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id

  lambda_name    = "${local.name}-api"
  lambda_handler = "com.utesa.api.lambda.StreamLambdaHandler::handleRequest"

  notification_lambda_name = var.notification_lambda_name

  # En el sandbox de SES el destinatario tambien debe estar verificado.
  ses_recipient_identities = setsubtract(toset(var.notification_test_recipients), [var.notification_sender_email])
}

# =============================================================================
# S3: paquete de la Lambda (privado) y archivos subidos por la app (privado, URLs firmadas)
# =============================================================================

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name}-artifacts-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "lambda_package" {
  bucket      = aws_s3_bucket.artifacts.id
  key         = "lambda/api-lambda.zip"
  source      = var.lambda_zip_path
  source_hash = filemd5(var.lambda_zip_path)
}

resource "aws_s3_bucket" "uploads" {
  bucket        = "${local.name}-uploads-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Bucket privado: la API devuelve URLs firmadas temporales para ver los archivos.
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = var.cors_allow_origins
    allowed_headers = ["*"]
    max_age_seconds = 3600
  }
}

# =============================================================================
# CloudWatch Logs
# =============================================================================

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = var.log_retention_days
}

# =============================================================================
# IAM: rol de ejecucion de la Lambda con permisos minimos
# =============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  # GetObject es necesario para que las URLs firmadas por la Lambda sean validas.
  statement {
    sid       = "ReadWriteUploads"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/uploads/*"]
  }

  statement {
    sid       = "PublishNotifications"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.notifications.arn]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.lambda_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# =============================================================================
# Lambda (Spring Boot)
# =============================================================================

resource "aws_lambda_function" "api" {
  function_name = local.lambda_name
  description   = "API REST Spring Boot (JWT + CRUD usuarios + upload)"
  role          = aws_iam_role.lambda.arn

  runtime       = "java17"
  handler       = local.lambda_handler
  architectures = ["x86_64"]
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  s3_bucket        = aws_s3_bucket.artifacts.id
  s3_key           = aws_s3_object.lambda_package.key
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  # SnapStart solo aplica a versiones publicadas; API Gateway invoca el alias "live".
  publish = true

  dynamic "snap_start" {
    for_each = var.snapstart_enabled ? [1] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  environment {
    variables = {
      DATABASE_URL           = var.database_url
      JWT_SECRET             = var.jwt_secret
      JWT_EXPIRATION_MS      = tostring(var.jwt_expiration_ms)
      APP_STORAGE            = "s3"
      S3_BUCKET              = aws_s3_bucket.uploads.id
      S3_PREFIX              = "uploads/"
      NOTIFICATIONS_PROVIDER = "sns"
      SNS_TOPIC_ARN          = aws_sns_topic.notifications.arn
      DB_POOL_SIZE           = "2"
      JAVA_TOOL_OPTIONS      = "-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_cloudwatch_log_group.lambda,
  ]
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Version publicada que recibe el trafico de API Gateway"
  function_name    = aws_lambda_function.api.function_name
  function_version = aws_lambda_function.api.version
}

# =============================================================================
# API Gateway (HTTP API) -> Lambda
# =============================================================================

resource "aws_apigatewayv2_api" "api" {
  name          = "${local.name}-http-api"
  protocol_type = "HTTP"
  description   = "Entrada publica de la app movil"

  # API Gateway responde los preflight OPTIONS sin invocar la Lambda.
  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["authorization", "content-type"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_alias.live.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

# Todas las rutas (/api/auth/**, /api/usuarios/**, /api/upload) van a Spring,
# que hace el ruteo y la seguridad JWT igual que en local.
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      path               = "$context.path"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
      integrationError   = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  qualifier     = aws_lambda_alias.live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# =============================================================================
# Mensajeria desacoplada: API -> SNS -> SQS -> notification-lambda -> SES (correo)
# =============================================================================

# -----------------------------------------------------------------------------
# SNS Topic: la Lambda principal publica aqui cada correo a enviar
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "notifications" {
  name = "${local.name}-notifications"
}

# -----------------------------------------------------------------------------
# SQS Queue (+ DLQ): amortigua los mensajes hasta que la Lambda los procesa
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "notifications_dlq" {
  name                      = "${local.name}-notifications-dlq"
  message_retention_seconds = 1209600 # 14 dias para revisar los mensajes que fallaron
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "notifications" {
  name                      = "${local.name}-notifications"
  message_retention_seconds = 345600 # 4 dias
  receive_wait_time_seconds = 20     # long polling
  sqs_managed_sse_enabled   = true
  # AWS recomienda al menos 6 veces el timeout de la Lambda que consume la cola.
  visibility_timeout_seconds = var.notification_lambda_timeout_seconds * 6

  # Tras 3 intentos fallidos el mensaje pasa a la DLQ en vez de reintentarse para siempre.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "notifications_dlq" {
  queue_url = aws_sqs_queue.notifications_dlq.id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.notifications.arn]
  })
}

# Solo el topic de notificaciones puede escribir en la cola.
data "aws_iam_policy_document" "notifications_queue" {
  statement {
    sid       = "AllowSnsTopic"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.notifications.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.notifications.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "notifications" {
  queue_url = aws_sqs_queue.notifications.id
  policy    = data.aws_iam_policy_document.notifications_queue.json
}

# -----------------------------------------------------------------------------
# Suscripcion SNS -> SQS
# -----------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "notifications_sqs" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notifications.arn

  # Sin la politica de la cola, SNS no puede entregar los mensajes.
  depends_on = [aws_sqs_queue_policy.notifications]
}

# -----------------------------------------------------------------------------
# SES: identidades de correo. AWS envia un correo de verificacion a cada direccion
# y hay que abrir el enlace antes de poder enviar (o, en sandbox, recibir).
# -----------------------------------------------------------------------------

resource "aws_sesv2_email_identity" "sender" {
  email_identity = var.notification_sender_email
}

resource "aws_sesv2_email_identity" "test_recipients" {
  for_each       = local.ses_recipient_identities
  email_identity = each.value
}

# -----------------------------------------------------------------------------
# CloudWatch Logs + IAM de la Lambda de notificaciones
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "notification_lambda" {
  name              = "/aws/lambda/${local.notification_lambda_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "notification_lambda" {
  name               = "${local.name}-notification-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "notification_lambda_permissions" {
  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.notification_lambda.arn}:*"]
  }

  statement {
    sid = "ConsumeQueue"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.notifications.arn]
  }

  # SES valida el permiso contra la identidad remitente y, en sandbox, tambien
  # contra la del destinatario; por eso el recurso es identity/* pero el
  # remitente queda fijado con la condicion.
  statement {
    sid       = "SendEmail"
    actions   = ["ses:SendEmail"]
    resources = ["arn:aws:ses:${var.aws_region}:${local.account_id}:identity/*"]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.notification_sender_email]
    }
  }
}

resource "aws_iam_role_policy" "notification_lambda" {
  name   = "${local.name}-notification-lambda-policy"
  role   = aws_iam_role.notification_lambda.id
  policy = data.aws_iam_policy_document.notification_lambda_permissions.json
}

# -----------------------------------------------------------------------------
# Lambda de notificaciones (Python, sin dependencias: boto3 viene en el runtime)
# -----------------------------------------------------------------------------

data "archive_file" "notification_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../notification-lambda"
  output_path = "${path.module}/build/notification-lambda.zip"
  excludes    = ["__pycache__", "README.md"]
}

resource "aws_lambda_function" "notification" {
  function_name = local.notification_lambda_name
  description   = "Consume la cola SQS de notificaciones y envia los correos con SES"
  role          = aws_iam_role.notification_lambda.arn

  runtime       = "python3.13"
  handler       = "handler.handler"
  architectures = ["arm64"]
  memory_size   = 128
  timeout       = var.notification_lambda_timeout_seconds

  filename         = data.archive_file.notification_lambda.output_path
  source_code_hash = data.archive_file.notification_lambda.output_base64sha256

  environment {
    variables = {
      SENDER_EMAIL     = var.notification_sender_email
      LOAD_TEST_MODE   = tostring(var.load_test_mode)
      SIMULATED_SES_MS = tostring(var.simulated_ses_ms)
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "INFO"
    log_group             = aws_cloudwatch_log_group.notification_lambda.name
  }

  depends_on = [
    aws_iam_role_policy.notification_lambda,
    aws_cloudwatch_log_group.notification_lambda,
  ]
}

# -----------------------------------------------------------------------------
# Event Source Mapping SQS -> Lambda
# -----------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "notifications_sqs" {
  event_source_arn = aws_sqs_queue.notifications.arn
  function_name    = aws_lambda_function.notification.arn
  enabled          = true

  batch_size                         = 10
  maximum_batching_window_in_seconds = 0

  # La Lambda devuelve los mensajes que fallaron; solo esos vuelven a la cola.
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 2
  }
}
