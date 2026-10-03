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

output "cloudwatch_logs_url" {
  description = "Acceso directo a los logs de la Lambda en la consola."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.lambda.name, "/", "$252F")}"
}
