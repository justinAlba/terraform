// Configuracion comun de todas las pruebas de carga.
//
// Variables de entorno (k6 -e NOMBRE=valor):
//   API_URL          URL base de API Gateway (terraform output -raw api_url). Obligatoria.
//   LOADTEST_EMAIL   Usuario con el que se obtiene el JWT (se registra si no existe).
//   LOADTEST_PASS    Contrasena de ese usuario.
//   THINK_TIME       Segundos de espera entre requests de cada usuario virtual (default 1).

export const API_URL = (__ENV.API_URL || '').replace(/\/+$/, '');
export const LOADTEST_EMAIL = __ENV.LOADTEST_EMAIL || 'loadtest@test.com';
export const LOADTEST_PASS = __ENV.LOADTEST_PASS || 'LoadTest#2026';
export const THINK_TIME = Number(__ENV.THINK_TIME ?? 1);

if (!API_URL) {
  throw new Error('Falta API_URL. Ejemplo: k6 run -e API_URL=https://xxxx.execute-api.us-east-1.amazonaws.com ...');
}

// Body exacto que pide la asignacion. test@test.com cae en el modo LOAD_TEST_MODE
// de notification-lambda, que simula SES en vez de enviar correos reales.
export const NOTIFICATION_BODY = JSON.stringify({
  email: 'test@test.com',
  subject: 'Prueba',
  message: 'Mensaje de carga',
});

// Estadisticas que se muestran y se exportan en el resumen.
export const TREND_STATS = ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'];
