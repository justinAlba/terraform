variable "aws_region" {
  description = "Region de AWS. En CI llega desde el secret AWS_REGION (TF_VAR_aws_region)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para nombrar los recursos."
  type        = string
}

variable "environment" {
  description = "Nombre del ambiente (dev, prod...)."
  type        = string
}

variable "lambda_zip_path" {
  description = "Ruta al paquete generado por `./mvnw -Plambda package`."
  type        = string
}

variable "lambda_memory_mb" {
  description = "Memoria de la Lambda. Mas memoria = mas CPU = arranque de Spring mas rapido."
  type        = number
  default     = 2048
}

variable "lambda_timeout_seconds" {
  description = "Timeout de la Lambda. API Gateway corta a los 30 s, no tiene sentido subirlo mas."
  type        = number
  default     = 30
}

variable "snapstart_enabled" {
  description = "Activa Lambda SnapStart para reducir el cold start de Spring Boot."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Dias que CloudWatch conserva los logs."
  type        = number
  default     = 7
}

variable "jwt_expiration_ms" {
  description = "Vigencia del JWT en milisegundos."
  type        = number
  default     = 3600000
}

variable "cors_allow_origins" {
  description = "Origenes permitidos por CORS en API Gateway."
  type        = list(string)
  default     = ["*"]
}

variable "throttling_rate_limit" {
  description = "Peticiones por segundo permitidas en el stage (protege la factura)."
  type        = number
  default     = 20
}

variable "throttling_burst_limit" {
  description = "Rafaga maxima de peticiones en el stage."
  type        = number
  default     = 50
}

# ---------------------------------------------------------------------------
# Secretos: NO van en terraform.tfvars. En CI llegan desde GitHub Secrets como
# TF_VAR_database_url y TF_VAR_jwt_secret.
# ---------------------------------------------------------------------------

variable "database_url" {
  description = "Cadena de conexion PostgreSQL (Neon), ej. postgresql://user:pass@host/db?sslmode=require"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Clave para firmar los JWT (minimo 32 caracteres)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jwt_secret) >= 32
    error_message = "jwt_secret debe tener al menos 32 caracteres."
  }
}
