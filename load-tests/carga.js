// Prueba de carga de POST /notifications/send.
//
// Un mismo script para todas las actividades; cada escenario cambia solo los
// parametros (ver run-*.ps1):
//   VUS        usuarios virtuales concurrentes
//   DURACION   duracion de la carga sostenida (ej. 1m, 2m)
//   RAMPA      tiempo de subida hasta VUS (default 0s = todos desde el inicio)
//   NOMBRE     carpeta de resultados (results/<NOMBRE>/)
//   ABORTAR    "true" en la prueba de estres: corta si errores > 5% o p95 > 5 s
//
// Ejemplo (linea base):
//   k6 run -e API_URL=... -e VUS=10 -e DURACION=1m -e NOMBRE=01-linea-base carga.js

import { sleep } from 'k6';
import { obtenerToken, enviarNotificacion } from './lib/api.js';
import { THINK_TIME, TREND_STATS } from './lib/config.js';
export { handleSummary } from './lib/resumen.js';

const VUS = Number(__ENV.VUS || 10);
const DURACION = __ENV.DURACION || '1m';
const RAMPA = __ENV.RAMPA || '0s';
const ABORTAR = __ENV.ABORTAR === 'true';

const ENDPOINT = '{name:POST /notifications/send}';

// Criterios de parada de la Actividad 4. En las demas pruebas solo se registran.
const criterio = (expr) => (ABORTAR ? [{ threshold: expr, abortOnFail: true, delayAbortEval: '20s' }] : [expr]);

export const options = {
  scenarios: {
    carga: {
      executor: 'ramping-vus',
      startVUs: RAMPA === '0s' ? VUS : 1,
      stages: [
        { duration: RAMPA, target: VUS },
        { duration: DURACION, target: VUS },
      ],
      gracefulRampDown: '10s',
      gracefulStop: '30s',
    },
  },
  summaryTrendStats: TREND_STATS,
  setupTimeout: '3m',
  thresholds: {
    // Los thresholds tambien hacen que k6 calcule las metricas solo del endpoint
    // bajo prueba (sin el login de setup) para el resumen.
    [`http_req_duration${ENDPOINT}`]: criterio('p(95)<5000'),
    [`http_req_failed${ENDPOINT}`]: criterio('rate<0.05'),
    [`http_reqs${ENDPOINT}`]: ['count>=0'],
    'http_reqs{status:429}': ['count>=0'],
  },
};

export function setup() {
  return { token: obtenerToken() };
}

export default function (data) {
  enviarNotificacion(data.token);
  if (THINK_TIME > 0) sleep(THINK_TIME);
}
