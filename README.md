# Despliegue Serverless con Terraform y CI/CD

API Spring Boot (JWT + CRUD de usuarios + subida de archivos) desplegada en **AWS Lambda** detras de **API Gateway**, con base de datos **Neon PostgreSQL**, infraestructura en **Terraform** y despliegue automatico con **GitHub Actions**. La app movil Ionic/Angular (MVVM) consume la URL de API Gateway.

## Arquitectura

```
App movil (Ionic)                      GitHub
      |                                   |
API Gateway (HTTP API)              GitHub Actions
      |                                   |
AWS Lambda (Spring Boot, SnapStart)  Terraform apply
      |            |                      |
Neon PostgreSQL   S3 (uploads)           AWS
```

| Carpeta | Contenido |
|---|---|
| `Actividad_API_BACKEND/` | API Spring Boot. El perfil Maven `lambda` genera `target/api-lambda.zip` |
| `terraform/` | `provider.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars` |
| `.github/workflows/deploy.yml` | Pipeline: Build → Test → Terraform Plan → Terraform Apply → Deploy Lambda |
| `appMovil/` | App Ionic + Angular (MVVM) |

### Recursos que crea Terraform

| Recurso | Para que |
|---|---|
| `aws_lambda_function` + `aws_lambda_alias` (`live`) | Ejecuta Spring Boot (Java 17). SnapStart reduce el cold start; API Gateway invoca el alias |
| `aws_apigatewayv2_api` / `stage` / `route` / `integration` | HTTP API publica, ruta `$default` → Lambda, CORS y throttling |
| `aws_iam_role` + `aws_iam_role_policy` | Rol de la Lambda: solo escribir sus logs y subir a `uploads/` del bucket |
| `aws_cloudwatch_log_group` (x2) | Logs de la Lambda y access logs de API Gateway (retencion 7 dias) |
| `aws_s3_bucket` artifacts | Paquete de la Lambda (~55 MB, supera el limite de 50 MB de subida directa) |
| `aws_s3_bucket` uploads | Archivos subidos desde la app (lectura publica solo en `uploads/*`) |

El estado de Terraform vive en un bucket S3 (`tfstate-<cuenta>-<region>`) que crea `terraform/scripts/init-backend.sh` la primera vez. Sin estado remoto, cada ejecucion del pipeline intentaria crear de nuevo los recursos.

### Cambios en el backend para correr en Lambda

- `StreamLambdaHandler` (en `src/lambda/java`, solo se compila con `-Plambda`) traduce los eventos de API Gateway a peticiones de Spring MVC; controllers, filtro JWT y Spring Security no cambian.
- `DATABASE_URL` en formato Neon (`postgresql://user:pass@host/db?sslmode=require`) se convierte a JDBC al arrancar. Sin esa variable, se siguen usando `DB_HOST`/`DB_USER`/... (local y Docker).
- Los uploads pasan por el puerto `AlmacenamientoArchivosPort`: en local se guardan en disco y en Lambda (`APP_STORAGE=s3`) en S3, porque el disco de Lambda es temporal. La respuesta trae la URL publica del archivo.
- Pruebas unitarias (`DatabaseUrlParserTest`, `JwtServiceTest`) que corre el pipeline.

## Puesta en marcha

### 1. Base de datos en Neon

1. Crear un proyecto en https://neon.tech (region AWS US East 1, la misma que la Lambda).
2. Copiar el *connection string* (formato `postgresql://...?sslmode=require`). Ese es el `DATABASE_URL`.
3. Las tablas las crea Hibernate al arrancar (`ddl-auto: update`).

### 2. Usuario IAM para GitHub Actions

En la consola de AWS, IAM → Users → crear un usuario (ej. `github-actions`) con estas politicas administradas:

- `AWSLambda_FullAccess`
- `AmazonAPIGatewayAdministrator`
- `IAMFullAccess`
- `AmazonS3FullAccess`
- `CloudWatchLogsFullAccess`

Luego Security credentials → Create access key (tipo *Application running outside AWS*). Guardar el Access Key ID y el Secret.

### 3. Secrets en GitHub

Repositorio → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key del usuario IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret del usuario IAM |
| `AWS_REGION` | `us-east-1` |
| `DATABASE_URL` | Connection string de Neon |
| `JWT_SECRET` | Texto aleatorio de 32+ caracteres (ej. salida de `openssl rand -base64 48`) |

Configurar los secrets **antes** del primer push a `main`, si no el pipeline falla en el plan.

> En los logs de Actions la region aparece como `***` (incluida dentro de la URL de la API) porque GitHub oculta cualquier texto igual a un secret. La URL completa se ve con `terraform output api_url` o en la consola de API Gateway.

### 4. Desplegar

Cada push a `main` ejecuta el pipeline completo. Los pull requests ejecutan Build, Test y Terraform Plan, sin aplicar cambios. Tambien se puede lanzar a mano desde la pestana Actions (*Run workflow*).

El primer `terraform apply` tarda unos minutos mas: SnapStart inicializa Spring Boot (y se conecta a Neon) al publicar la version de la Lambda.

### 5. Conectar la app movil

Con la URL que muestra el resumen del job *Deploy Lambda* (o `terraform output api_url`):

```bash
cd appMovil
npm run set-api-url -- https://<api-id>.execute-api.us-east-1.amazonaws.com
npm run start:aws          # navegador, usando la API en AWS
# o para Android:
npx ng build && npx cap sync android && npx cap open android
```

La pantalla *Configurar servidor* de la app sigue permitiendo cambiar la URL sin recompilar.

## Ejecutar Terraform desde la maquina local (opcional)

Requiere Terraform >= 1.10 y AWS CLI configurado.

```bash
cd Actividad_API_BACKEND && ./mvnw -Plambda package && cd ..
cd terraform
export AWS_REGION=us-east-1 TF_VAR_aws_region=us-east-1
export TF_VAR_database_url='postgresql://...' TF_VAR_jwt_secret='...'
./scripts/init-backend.sh
terraform plan
```

Usa el mismo estado remoto que el pipeline. Para borrar todo: `terraform destroy`.

## Limites a tener en cuenta

- **Tamano de archivos**: Lambda acepta hasta 6 MB por peticion y API Gateway envia los archivos en base64 (+33 %), asi que el maximo practico por upload es de ~4 MB.
- **Timeout**: API Gateway corta a los 30 s.
- **Costos**: con el uso de una demo todo entra en la capa gratuita (Lambda, API Gateway HTTP, S3, CloudWatch, Neon free). El stage limita a 20 req/s para evitar sorpresas.
