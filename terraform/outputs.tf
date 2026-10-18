output "api_url" {
  description = "URL base de la API. Es la que se configura en la app movil (environment.prod.ts)."
  # Sin la "/" final: la app concatena rutas que ya empiezan con "/" y Spring
  # Security rechaza las URLs con "//".
  value = trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")
}

output "lambda_function_name" {
  value = aws_lambda_function.api.function_name
}

output "lambda_live_version" {
  description = "Version publicada a la que apunta el alias live."
  value       = aws_lambda_alias.live.function_version
}

output "uploads_bucket" {
  value = aws_s3_bucket.uploads.id
}

output "lambda_log_group" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "api_gateway_log_group" {
  value = aws_cloudwatch_log_group.api_gateway.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.notifications.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.notifications.url
}

output "sqs_dlq_url" {
  description = "Cola de mensajes que fallaron 3 veces."
  value       = aws_sqs_queue.notifications_dlq.url
}

output "notification_lambda_name" {
  value = aws_lambda_function.notification.function_name
}

output "notification_lambda_log_group" {
  value = aws_cloudwatch_log_group.notification_lambda.name
}

output "notification_logs_url" {
  description = "Acceso directo a los logs de la Lambda de notificaciones en la consola."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.notification_lambda.name, "/", "$252F")}"
}

output "cloudwatch_logs_url" {
  description = "Acceso directo a los logs de la Lambda en la consola."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.lambda.name, "/", "$252F")}"
}

output "dashboard_pruebas_carga_url" {
  description = "Dashboard de CloudWatch con las metricas de las pruebas de carga."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards/dashboard/${aws_cloudwatch_dashboard.pruebas_carga.dashboard_name}"
}
