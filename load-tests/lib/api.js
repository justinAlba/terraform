import http from 'k6/http';
import { check, sleep } from 'k6';
import { API_URL, LOADTEST_EMAIL, LOADTEST_PASS, NOTIFICATION_BODY } from './config.js';

const JSON_HEADERS = { 'Content-Type': 'application/json' };

/**
 * Obtiene un JWT para la prueba. El endpoint /notifications/send exige token,
 * asi que se hace una sola vez en setup() y lo comparten todos los usuarios virtuales.
 * Reintenta porque el primer request puede caer en un cold start de la Lambda.
 */
export function obtenerToken() {
  const credenciales = JSON.stringify({ email: LOADTEST_EMAIL, password: LOADTEST_PASS });

  for (let intento = 1; intento <= 5; intento++) {
    let res = http.post(`${API_URL}/api/auth/login`, credenciales, {
      headers: JSON_HEADERS,
      tags: { name: 'setup-login' },
      timeout: '40s',
    });

    if (res.status === 401) {
      // El usuario aun no existe: se registra y se vuelve a intentar el login.
      http.post(
        `${API_URL}/api/auth/registro`,
        JSON.stringify({ nombre: 'Usuario Load Test', email: LOADTEST_EMAIL, password: LOADTEST_PASS }),
        { headers: JSON_HEADERS, tags: { name: 'setup-registro' }, timeout: '40s' },
      );
      res = http.post(`${API_URL}/api/auth/login`, credenciales, {
        headers: JSON_HEADERS,
        tags: { name: 'setup-login' },
        timeout: '40s',
      });
    }

    if (res.status === 200) {
      return res.json('token');
    }
    console.warn(`Login intento ${intento}: HTTP ${res.status} ${res.body}`);
    sleep(5);
  }
  throw new Error('No se pudo obtener el JWT; revisa API_URL y que la API este desplegada.');
}

export function enviarNotificacion(token) {
  const res = http.post(`${API_URL}/notifications/send`, NOTIFICATION_BODY, {
    headers: { ...JSON_HEADERS, Authorization: `Bearer ${token}` },
    tags: { name: 'POST /notifications/send' },
    timeout: '30s',
  });

  check(res, {
    'status 202': (r) => r.status === 202,
    'sin throttling (429)': (r) => r.status !== 429,
  });
  return res;
}
