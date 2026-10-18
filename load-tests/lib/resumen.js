import { textSummary } from 'https://jslib.k6.io/k6-summary/0.1.0/index.js';

const NOMBRE = __ENV.NOMBRE || 'prueba';

function valor(metrica, stat) {
  return metrica && metrica.values[stat] !== undefined ? metrica.values[stat] : null;
}

/**
 * Exporta, ademas del resumen completo de k6, un JSON compacto con exactamente
 * las metricas que pide la asignacion. Lo consume scripts/graficas.py.
 */
export function handleSummary(data) {
  const m = data.metrics;
  // Solo cuenta el endpoint bajo prueba, no el login de setup().
  const dur = m['http_req_duration{name:POST /notifications/send}'] || m.http_req_duration;
  const reqs = m['http_reqs{name:POST /notifications/send}'] || m.http_reqs;
  const fallidos = m['http_req_failed{name:POST /notifications/send}'] || m.http_req_failed;
  const estado429 = m['http_reqs{status:429}'];

  const resumen = {
    escenario: NOMBRE,
    vus: Number(__ENV.VUS) || null,
    duracion: __ENV.DURACION || null,
    think_time_s: Number(__ENV.THINK_TIME ?? 1),
    fecha_fin: new Date().toISOString(),
    duracion_real_s: data.state.testRunDurationMs / 1000,
    requests: valor(reqs, 'count'),
    throughput_rps: valor(reqs, 'rate'),
    latencia_ms: {
      promedio: valor(dur, 'avg'),
      minimo: valor(dur, 'min'),
      mediana: valor(dur, 'med'),
      maximo: valor(dur, 'max'),
      p90: valor(dur, 'p(90)'),
      p95: valor(dur, 'p(95)'),
      p99: valor(dur, 'p(99)'),
    },
    tasa_errores: valor(fallidos, 'rate'),
    respuestas_429: estado429 ? valor(estado429, 'count') : 0,
  };

  return {
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
    [`results/${NOMBRE}/summary.json`]: JSON.stringify(data, null, 2),
    [`results/${NOMBRE}/metricas.json`]: JSON.stringify(resumen, null, 2),
  };
}
