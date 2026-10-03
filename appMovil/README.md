# App Movil - Ionic Angular

App movil en Ionic + Angular (TypeScript) que consume la API de `Actividad_API_BACKEND` (Spring Boot + JWT + PostgreSQL).

## Requisitos

- Node.js 22.12+ (probado con 22.17.1)
- El backend corriendo en `http://localhost:8080` (ver `Actividad_API_BACKEND/README.md`, incluye instrucciones Docker)

## Configuracion de la URL del backend

En `src/environments/environment.ts`:

- Navegador (`ionic serve`): `http://localhost:8080`
- Emulador Android: `http://10.0.2.2:8080`
- Dispositivo fisico: IP de la maquina donde corre el backend, ej. `http://192.168.1.100:8080`

## Ejecutar

```bash
npm install
npm start        # equivalente a: ng serve
```

Abre `http://localhost:4200`.

## Arquitectura (MVVM)

```
src/app/
  core/
    models/         Interfaces TS que reflejan los DTOs del backend (Usuario, LoginRequest, TokenResponse, UploadResponse...)
    services/       HttpClient puro contra la API (AuthService, UsuarioService, UploadService, DashboardService, TokenStorageService)
    interceptors/   JwtInterceptor (agrega Authorization: Bearer) y ErrorInterceptor (logout automatico en 401/403)
    guards/         AuthGuard (protege rutas que requieren sesion)
  repositories/     Capa intermedia entre ViewModel y Service (AuthRepository, UsuarioRepository, UploadRepository, DashboardRepository)
  pages/
    login/          View (login.page.ts/html) + ViewModel (login.viewmodel.ts)
    register/
    dashboard/       Demuestra consumo en paralelo con forkJoin (usuarios + perfil + configuracion)
    usuarios-list/   CRUD: listar, ir a editar, eliminar
    usuario-form/     CRUD: crear / editar (mismo formulario, ruta usuario-form o usuario-form/:id)
    upload/           Seleccion de imagen (Capacitor Camera) o documento, preview y barra de progreso
```

Cada pagina sigue el mismo patron: la **View** (`*.page.ts` + `*.page.html`) solo se encarga de renderizar y capturar eventos, delegando toda la logica y el estado (loading, error, datos) a un **ViewModel** inyectado como provider de la propia pagina. El ViewModel llama al **Repository** correspondiente, que a su vez usa el **Service** con las llamadas HTTP reales.

## JWT

El token se guarda con `@ionic/storage-angular` (`TokenStorageService`). El `JwtInterceptor` lo agrega a toda peticion que no sea `/auth/**`. El `ErrorInterceptor` limpia el token y redirige a `/login` si el backend responde 401/403 en una ruta protegida. El JWT incluye el `id` numerico del usuario (ademas de `sub`=email y `rol`), usado para pedir el perfil propio en el dashboard.

## Concurrencia (forkJoin)

`DashboardRepository.cargar()` dispara simultaneamente `GET /api/usuarios`, `GET /api/usuarios/{id}` (perfil propio) y una configuracion simulada, combinandolas con `forkJoin` de RxJS.

## Subida de archivos

`UploadService.subir()` usa `HttpClient.request(new HttpRequest('POST', url, formData, { reportProgress: true }))`, y `UploadRepository` traduce los eventos `HttpEventType.UploadProgress`/`Response` a un estado `{ progreso, completado, resultado }` que la vista pinta con `<ion-progress-bar>`.
