import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const project = path.resolve(here, '..');
const npm = process.platform === 'win32' ? 'npx.cmd' : 'npx';

const watcher = spawn(process.execPath, [path.join(project, 'scripts', 'watch-web.mjs')], {
  cwd: project,
  stdio: 'inherit',
});

const expo = spawn(npm, ['expo', 'start', '--lan', '--port', '8081'], {
  cwd: project,
  stdio: 'inherit',
  shell: process.platform === 'win32',
});

function stop() {
  try { watcher.kill(); } catch (_) {}
  try { expo.kill(); } catch (_) {}
  process.exit(0);
}

process.on('SIGINT', stop);
process.on('SIGTERM', stop);
expo.on('exit', (code) => {
  try { watcher.kill(); } catch (_) {}
  process.exit(code == null ? 0 : code);
});
