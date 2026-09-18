// Renders the PNG icons and the Open Graph image with headless Chrome.
// Run once (or after changing the artwork): `node tools/render-images.mjs`
// Output goes to public/img and is committed, so normal builds don't need Chrome.

import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const img = join(root, 'public/img');
const logo = readFileSync(join(img, 'favicon.svg'), 'utf8');

const chrome = [
  process.env.CHROME_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
].find((p) => p && existsSync(p));
if (!chrome) throw new Error('Chrome not found — set CHROME_PATH.');

const tmp = mkdtempSync(join(tmpdir(), 'swipr-img-'));

function render(name, width, height, html) {
  const page = join(tmp, `${name}.html`);
  writeFileSync(page, `<!doctype html><meta charset="utf-8"><style>html,body{margin:0;width:${width}px;height:${height}px;overflow:hidden;background:#0a0a0a}</style>${html}`);
  execFileSync(chrome, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--force-device-scale-factor=1',
    `--window-size=${width},${height}`,
    `--screenshot=${join(img, name)}`,
    pathToFileURL(page).href,
  ], { stdio: 'ignore' });
  console.log(`rendered ${name} (${width}×${height})`);
}

const icon = (size, padding) =>
  `<div style="width:${size}px;height:${size}px;display:grid;place-items:center;background:#141414">
     <div style="width:${size - padding * 2}px;height:${size - padding * 2}px">${logo.replace('<svg ', '<svg width="100%" height="100%" ')}</div>
   </div>`;

render('icon-32.png', 32, 32, `<div style="width:32px;height:32px">${logo.replace('<svg ', '<svg width="32" height="32" ')}</div>`);
render('apple-touch-icon.png', 180, 180, icon(180, 8));
render('icon-192.png', 192, 192, icon(192, 10));
render('icon-512.png', 512, 512, icon(512, 24));

const card = (x, y, rot, bg, extra = '') =>
  `<div style="position:absolute;left:${x}px;top:${y}px;width:250px;height:340px;border-radius:26px;transform:rotate(${rot}deg);background:${bg};box-shadow:0 30px 60px rgba(0,0,0,.6);overflow:hidden">${extra}</div>`;

render('og-image.png', 1200, 630, `
<div style="position:relative;width:1200px;height:630px;overflow:hidden;font-family:'Segoe UI',system-ui,-apple-system,Roboto,Arial,sans-serif;color:#f5f5f5;background:radial-gradient(700px 500px at 88% 30%,rgba(31,162,255,.22),transparent 70%),#0a0a0a">
  <div style="position:absolute;left:80px;top:78px;display:flex;align-items:center;gap:16px">
    <div style="width:64px;height:64px">${logo.replace('<svg ', '<svg width="64" height="64" ')}</div>
    <div style="font-size:40px;font-weight:800;letter-spacing:-1px">Swipr</div>
  </div>
  <div style="position:absolute;left:80px;top:200px;width:600px;font-size:66px;line-height:1.05;font-weight:800;letter-spacing:-2px">
    Clean up your camera roll, <span style="color:#1fa2ff">one swipe at a time.</span>
  </div>
  <div style="position:absolute;left:80px;top:480px;display:flex;gap:28px;font-size:26px;color:#a3a3a3">
    <span><b style="color:#30d158">→</b> keep</span><span><b style="color:#ff453a">←</b> delete</span><span>Free · 100% on-device</span>
  </div>
  ${card(760, 150, -8, '#1d1d1d')}
  ${card(850, 130, 9, 'linear-gradient(to bottom,#ff9a4d,#ff5e3a 55%,#c2372a)',
    `<div style="position:absolute;left:0;right:0;bottom:0;height:90px;background:#1b1410"></div>
     <div style="position:absolute;left:95px;top:170px;width:60px;height:60px;border-radius:50%;background:#ffd27a"></div>
     <div style="position:absolute;left:22px;top:26px;padding:2px 12px;border:4px solid #30d158;border-radius:10px;color:#30d158;font-size:34px;font-weight:900;transform:rotate(-14deg)">KEEP</div>`)}
</div>`);
