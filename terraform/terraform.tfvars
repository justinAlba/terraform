# Valores no sensibles. aws_region, database_url y jwt_secret llegan desde
# GitHub Secrets (TF_VAR_aws_region, TF_VAR_database_url, TF_VAR_jwt_secret).

project_name    = "actividad-api"
environment     = "prod"
lambda_zip_path = "../Actividad_API_BACKEND/target/api-lambda.zip"

lambda_memory_mb       = 2048
lambda_timeout_seconds = 30
snapstart_enabled      = true
log_retention_days     = 7
jwt_expiration_ms      = 3600000

cors_allow_origins = ["*"]
