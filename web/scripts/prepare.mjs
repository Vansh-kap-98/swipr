// Runs before every build: reads the app version from pubspec.yaml, copies the
// release APK into public/downloads, and records its size and SHA-256 so the
// download page can show them. Output: lib/build-info.json
import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const pubspec = readFileSync(resolve(root, '../pubspec.yaml'), 'utf8');
const version = pubspec.match(/^version:\s*([\d.]+)/m)?.[1] ?? '1.0.0';

const config = readFileSync(join(root, 'site.config.ts'), 'utf8');
const apkEnabled = /enabled:\s*true/.test(config);
const apkSource = config.match(/source:\s*'([^']+)'/)?.[1];

const externalUrl = config.match(/externalUrl:\s*'([^']+)'/)?.[1] ?? null;

let apk = { enabled: false };
if (apkEnabled && apkSource) {
  const from = resolve(root, apkSource);
  if (existsSync(from)) {
    const bytes = readFileSync(from);
    const fileName = `swipr-${version}.apk`;
    // Hosting it elsewhere (a GitHub release, say)? Then don't copy it into the
    // site — just link out, while still showing this file's size and checksum.
    if (!externalUrl) {
      mkdirSync(join(root, 'public/downloads'), { recursive: true });
      copyFileSync(from, join(root, 'public/downloads', fileName));
    }
    apk = {
      enabled: true,
      url: externalUrl ?? `/downloads/${fileName}`,
      fileName,
      sizeMb: (bytes.length / 1024 / 1024).toFixed(1),
      sha256: createHash('sha256').update(bytes).digest('hex'),
    };
  } else if (existsSync(join(root, 'public/downloads', `swipr-${version}.apk`))) {
    // No local Flutter build output — this is a deploy host (Vercel, Netlify…)
    // building from the repo. The APK committed under public/downloads is the
    // file that will be served, so measure that one.
    const fileName = `swipr-${version}.apk`;
    const bytes = readFileSync(join(root, 'public/downloads', fileName));
    apk = {
      enabled: true,
      url: externalUrl ?? `/downloads/${fileName}`,
      fileName,
      sizeMb: (bytes.length / 1024 / 1024).toFixed(1),
      sha256: createHash('sha256').update(bytes).digest('hex'),
    };
    console.warn(`  (using the committed public/downloads/${fileName})`);
  } else if (externalUrl && existsSync(join(root, 'lib/build-info.json'))) {
    // No local APK, but the file is hosted elsewhere: reuse the size and
    // checksum recorded by the last local build. Only safe when the link
    // points off-site — otherwise it would advertise a file this deploy
    // doesn't contain.
    apk = JSON.parse(readFileSync(join(root, 'lib/build-info.json'), 'utf8')).apk ?? { enabled: false };
    console.warn(`! APK not found at ${from} — linking to ${externalUrl} with the last recorded size/checksum.`);
  } else {
    console.warn(`! APK not found at ${from}`);
    console.warn('  The direct download is hidden rather than linking to a file this deploy lacks.');
    console.warn('  Either commit web/public/downloads/, or set apk.externalUrl in site.config.ts.');
  }
}

writeFileSync(
  join(root, 'lib/build-info.json'),
  `${JSON.stringify({ version, apk, builtAt: new Date().toISOString().slice(0, 10) }, null, 2)}\n`,
);

// Web app manifest (kept here so it shares site.config.ts's values).
const name = config.match(/name:\s*'([^']+)'/)?.[1] ?? 'Swipr';
const tagline = config.match(/tagline:\s*'([^']+)'/)?.[1] ?? '';
const themeColor = config.match(/themeColor:\s*'([^']+)'/)?.[1] ?? '#0A0A0A';
writeFileSync(
  join(root, 'public/site.webmanifest'),
  `${JSON.stringify(
    {
      name,
      short_name: name,
      description: tagline,
      start_url: '/',
      display: 'standalone',
      background_color: themeColor,
      theme_color: themeColor,
      icons: [
        { src: '/img/icon-192.png', sizes: '192x192', type: 'image/png' },
        { src: '/img/icon-512.png', sizes: '512x512', type: 'image/png' },
        { src: '/img/favicon.svg', sizes: 'any', type: 'image/svg+xml' },
      ],
    },
    null,
    2,
  )}\n`,
);

// favicon.ico: an ICO container wrapping the 32px PNG (valid in all browsers),
// so browsers' automatic /favicon.ico request doesn't 404.
const png32 = join(root, 'public/img/icon-32.png');
if (existsSync(png32)) {
  const png = readFileSync(png32);
  const header = Buffer.alloc(22);
  header.writeUInt16LE(1, 2); // type: icon
  header.writeUInt16LE(1, 4); // image count
  header.writeUInt8(32, 6); // width
  header.writeUInt8(32, 7); // height
  header.writeUInt16LE(1, 10); // colour planes
  header.writeUInt16LE(32, 12); // bits per pixel
  header.writeUInt32LE(png.length, 14);
  header.writeUInt32LE(22, 18); // offset to the image data
  writeFileSync(join(root, 'public/favicon.ico'), Buffer.concat([header, png]));
}
console.log(`prepare: app v${version}${apk.enabled ? `, ${apk.fileName} (${apk.sizeMb} MB)` : ', no APK'}`);
