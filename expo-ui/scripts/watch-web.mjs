import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';

const here = path.dirname(fileURLToPath(import.meta.url));
const project = path.resolve(here, '..');
const webDir = path.resolve(project, '..', 'web-prototype');
const buildScript = path.join(project, 'scripts', 'build-web.mjs');

let timer = null;
let building = false;
let queued = false;

function rebuild() {
  if (building) {
    queued = true;
    return;
  }
  building = true;
  queued = false;
  const child = spawn(process.execPath, [buildScript], { stdio: 'inherit' });
  child.on('exit', (code) => {
    building = false;
    if (queued) {
      queued = false;
      rebuild();
    }
    if (code !== 0) console.error(`[watch-web] build exited ${code}`);
  });
}

console.log(`[watch-web] watching ${webDir}`);
fs.watch(webDir, { recursive: true }, (event, filename) => {
  if (!filename) return;
  if (filename.includes('node_modules')) return;
  clearTimeout(timer);
  timer = setTimeout(rebuild, 180);
});
