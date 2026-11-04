import { createApp } from './app.js';
import { payosConfigured } from './config.js';
import { createRuntime } from './runtime.js';
import { startWorkflowWatcher } from './watcher.js';

try {
  process.loadEnvFile('.env');
} catch {
  // .env is optional; real deployments inject environment variables.
}

const runtime = createRuntime();
const app = createApp(runtime);
app.listen(runtime.config.port, () => {
  const payos = payosConfigured(runtime.config) ? 'configured' : 'NOT configured (checkout fails closed)';
  console.info(`[beewise-backend] listening on :${runtime.config.port}; payOS ${payos}`);
});
if (process.env.WORKFLOW_WATCHER === '1') {
  startWorkflowWatcher(runtime);
  console.info('[beewise-backend] workflow watcher enabled');
}
