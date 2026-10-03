# Actividad API Backend

API REST en Spring Boot con autenticación JWT y CRUD de usuarios, construida con Arquitectura Hexagonal (Puertos y Adaptadores).

## Estructura

```
com.utesa.api
├── domain            # Modelos, puertos (in/out) y excepciones. Sin dependencias de frameworks.
├── application       # Casos de uso que implementan los puertos de entrada.
└── infrastructure    # Adaptadores: REST (in/web), JPA (out/persistence) y seguridad JWT (config).
```

## Requisitos

- Java 17 o superior
- PostgreSQL 14 o superior
- Postman (o curl) para probar

## Configuración

1. Crear la base de datos (las tablas las crea Hibernate al arrancar):

```sql
CREATE DATABASE actividad_api;
```

2. Ajustar usuario y contraseña de PostgreSQL en `src/main/resources/application.yml` (`spring.datasource.username` y `spring.datasource.password`).

Variables de entorno opcionales:
| Variable | Descripción | Por defecto |
|---|---|---|
| `JWT_SECRET` | Clave de firma de los tokens (mínimo 32 caracteres) | definida en `application.yml` |
| `JWT_EXPIRATION_MS` | Vigencia del token en milisegundos | `3600000` (1 hora) |

## Ejecutar

Desde la carpeta del proyecto:

```bash
# Windows
mvnw.cmd spring-boot:run

# Linux / Mac / Git Bash
./mvnw spring-boot:run
```

La API queda disponible en `http://localhost:8080`. Para detenerla: `Ctrl + C`.

## Ejecutar con Docker

Requiere Docker Desktop. Desde la carpeta del proyecto:

```bash
docker compose up --build
```

Esto levanta dos contenedores: `db` (PostgreSQL 16, con volumen persistente) y `api` (la app, esperando a que la base este saludable antes de arrancar). La API queda en `http://localhost:8080` igual que en local. Los archivos subidos por `/api/upload` se guardan en el volumen `uploads_data`, montado en `/data/uploads`.

Variables configurables en `docker-compose.yml`: `JWT_SECRET`, `JWT_EXPIRATION_MS`, `DB_USER`, `DB_PASSWORD`, `UPLOAD_DIR`.

Para detener: `docker compose down` (agrega `-v` si tambien quieres borrar los volumenes de datos).

## Endpoints

| Método | Ruta | Token | Body |
|---|---|---|---|
| POST | `/api/auth/registro` | No | `{nombre, email, password}` |
| POST | `/api/auth/login` | No | `{email, password}` |
| GET | `/api/usuarios` | Sí | n/a |
| GET | `/api/usuarios/{id}` | Sí | n/a |
| POST | `/api/usuarios` | Sí | `{nombre, email, password, rol}` |
| PUT | `/api/usuarios/{id}` | Sí | `{nombre, email, password?, rol}` |
| DELETE | `/api/usuarios/{id}` | Sí | n/a |
| POST | `/api/upload` | Sí | `multipart/form-data`, campo `file` |

Reglas: `password` mínimo 6 caracteres; `rol` solo acepta `ADMIN` o `USUARIO`; en el PUT, `password` es opcional. El registro crea usuarios con rol `USUARIO`.

`POST /api/upload` recibe un `MultipartFile` en el campo `file`, lo guarda con un nombre unico (UUID) en el directorio configurado por `app.upload-dir` (por defecto `./uploads`, o `/data/uploads` dentro de Docker), y responde `{"filename": "...", "url": "/uploads/<nombre>"}`. El archivo queda accesible publicamente en `GET http://localhost:8080/uploads/<nombre>`.

## Uso en Postman

1. **Registrar un usuario**: `POST http://localhost:8080/api/auth/registro`, pestaña Body → raw → JSON:

```json
{
  "nombre": "Ana",
  "email": "ana@test.com",
  "password": "secreto123"
}
```

2. **Iniciar sesión**: `POST http://localhost:8080/api/auth/login`:

```json
{
  "email": "ana@test.com",
  "password": "secreto123"
}
```

La respuesta trae `{"token": "eyJ...", "tipo": "Bearer"}`. Copia el valor de `token`.

3. **Usar el token**: en las peticiones a `/api/usuarios`, pestaña Authorization → Type: Bearer Token → pega el token.

4. **Crear un usuario** (con token): `POST http://localhost:8080/api/usuarios`:

```json
{
  "nombre": "Beto",
  "email": "beto@test.com",
  "password": "clave123",
  "rol": "ADMIN"
}
```

## Códigos de respuesta

| Código | Significado |
|---|---|
| 200 | Correcto |
| 201 | Recurso creado |
| 204 | Eliminado |
| 400 | Datos inválidos (el JSON detalla cada campo) |
| 401 | Credenciales incorrectas |
| 403 | Falta el token, o es inválido o expiró |
| 404 | Usuario no encontrado |
| 409 | Ya existe un usuario con ese email |
