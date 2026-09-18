// Renders the app icon source images with headless Chrome, then
// `dart run flutter_launcher_icons` turns them into every Android and iOS size.
//
//   node tool/render_app_icon.mjs
//
// Output (committed, so a normal build never needs Chrome):
//   assets/icon/icon.png             1024 opaque      — iOS + legacy Android
//   assets/icon/icon_foreground.png  1024 transparent — Android adaptive foreground
//   assets/icon/icon_monochrome.png  1024 white       — Android 13+ themed icon

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'assets/icon');
mkdirSync(outDir, { recursive: true });

const chrome = [
  process.env.CHROME_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
].find((p) => p && existsSync(p));
if (!chrome) throw new Error('Chrome not found — set CHROME_PATH.');

const tmp = mkdtempSync(join(tmpdir(), 'swipr-icon-'));

/**
 * The mark: a photo card being swiped off a stack, with a check on it.
 * `scale` shrinks the art for the Android adaptive icon's safe zone.
 */
const mark = ({ scale = 1, mono = false } = {}) => `
<div class="mark">
  <div class="card back"></div>
  <div class="card front">
    ${mono ? '' : '<div class="sky"></div><div class="ground"></div>'}
    <svg class="check" viewBox="0 0 48 48" fill="none" stroke="${mono ? '#0a0a0a' : '#0A0A0A'}" stroke-width="7.5"
         stroke-linecap="round" stroke-linejoin="round"><path d="M12 25l9 9 16-19"/></svg>
  </div>
</div>
<style>
  .mark { position: relative; width: ${Math.round(1024 * scale)}px; height: ${Math.round(1024 * scale)}px; }
  .card { position: absolute; border-radius: ${Math.round(96 * scale)}px; overflow: hidden; }
  .back {
    width: 46%; height: 62%; left: 12%; top: 19%;
    background: ${mono ? 'rgba(255,255,255,.35)' : '#2A2A2A'};
    transform: rotate(-14deg);
  }
  .front {
    width: 50%; height: 68%; left: 33%; top: 16%;
    background: ${mono ? '#ffffff' : '#1FA2FF'};
    transform: rotate(11deg);
    display: grid; place-items: center;
  }
  .sky { position: absolute; inset: 0; background: linear-gradient(to bottom, #6fc8ff, #1FA2FF 60%); }
  .ground { position: absolute; left: 0; right: 0; bottom: 0; height: 30%; background: #0d63a8; }
  .check { position: relative; width: 62%; }
</style>`;

function render(name, { background, scale = 1, mono = false }) {
  const page = join(tmp, `${name}.html`);
  writeFileSync(
    page,
    `<!doctype html><meta charset="utf-8">
     <style>html,body{margin:0;width:1024px;height:1024px;overflow:hidden;background:${background};
       display:grid;place-items:center;font-family:system-ui}</style>
     ${mark({ scale, mono })}`,
  );
  execFileSync(
    chrome,
    [
      '--headless=new',
      `--user-data-dir=${join(tmp, `profile-${name}`)}`,
      '--disable-gpu',
      '--hide-scrollbars',
      '--force-device-scale-factor=1',
      '--default-background-color=00000000',
      '--window-size=1024,1024',
      `--screenshot=${join(outDir, name)}`,
      pathToFileURL(page).href,
    ],
    { stdio: 'ignore' },
  );
  console.log(`rendered assets/icon/${name}`);
}

// iOS and legacy Android: opaque, art fills the tile.
render('icon.png', { background: '#0F1012' });
// Adaptive foreground: flutter_launcher_icons insets this by 16%, which puts
// the art inside the launcher's safe zone.
render('icon_foreground.png', { background: 'transparent', scale: 0.92 });
// Themed icon (Android 13+): a flat white silhouette on transparent.
render('icon_monochrome.png', { background: 'transparent', scale: 0.92, mono: true });
