// Escribe la URL de API Gateway (output `api_url` de Terraform) en environment.prod.ts.
// Uso: npm run set-api-url -- https://abc123.execute-api.us-east-1.amazonaws.com
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const url = (process.argv[2] ?? '').trim().replace(/\/+$/, '');

if (!/^https:\/\/.+/.test(url)) {
  console.error('Uso: npm run set-api-url -- https://<api-id>.execute-api.<region>.amazonaws.com');
  process.exit(1);
}

const destino = fileURLToPath(new URL('../src/environments/environment.prod.ts', import.meta.url));

writeFileSync(
  destino,
  `export const environment = {
  production: true,
  // URL generada por API Gateway (terraform output api_url)
  baseUrl: '${url}',
};
`,
);

console.log(`environment.prod.ts -> ${url}`);
