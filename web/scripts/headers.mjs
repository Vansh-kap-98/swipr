// Runs after `next build`. Next inlines small hydration scripts in each page,
// so a strict content security policy needs their hashes. This collects every
// inline script in out/ and writes the final out/_headers.
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'out');

const walk = (dir) =>
  readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });

const hashes = new Set();
let inlineStyles = 0;
for (const file of walk(out).filter((f) => f.endsWith('.html'))) {
  const html = readFileSync(file, 'utf8');
  for (const [, body] of html.matchAll(/<script(?![^>]*\ssrc=)[^>]*>([\s\S]*?)<\/script>/g)) {
    if (body.trim()) hashes.add(`'sha256-${createHash('sha256').update(body).digest('base64')}'`);
  }
  inlineStyles += (html.match(/<style/g) ?? []).length;
}

const scriptSrc = ["'self'", ...hashes].join(' ');
// Next may inline critical CSS; allow inline styles only if it actually did.
const styleSrc = inlineStyles > 0 ? "'self' 'unsafe-inline'" : "'self'";

writeFileSync(
  join(out, '_headers'),
  `/*
  Content-Security-Policy: default-src 'none'; script-src ${scriptSrc}; style-src ${styleSrc}; img-src 'self' data:; font-src 'self'; manifest-src 'self'; connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=(), interest-cohort=()
  Strict-Transport-Security: max-age=31536000; includeSubDomains

/_next/static/*
  Cache-Control: public, max-age=31536000, immutable

/img/*
  Cache-Control: public, max-age=31536000, immutable

/downloads/*
  Content-Type: application/vnd.android.package-archive
  Content-Disposition: attachment
`,
);

console.log(`headers: ${hashes.size} inline script hash(es), inline styles: ${inlineStyles > 0 ? 'yes' : 'none'}`);
