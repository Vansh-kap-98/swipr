// Pre-deploy checks for out/: SEO metadata, structured data, links and assets.
// Run after building: `npm run check`
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'out');
const siteUrl = (readFileSync(join(root, 'site.config.ts'), 'utf8').match(/url:\s*'([^']+)'/) ?? [])[1];

const walk = (dir) =>
  readdirSync(dir).flatMap((entry) => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });

const pages = walk(out).filter((f) => f.endsWith('.html'));
let problems = 0;
const fail = (page, message) => {
  problems++;
  console.log(`✗ ${page}: ${message}`);
};

for (const file of pages) {
  const html = readFileSync(file, 'utf8');
  const name = file.slice(out.length).replaceAll('\\', '/');
  const get = (re) => html.match(re)?.[1];
  const title = get(/<title>([^<]*)<\/title>/);
  const description = get(/<meta name="description" content="([^"]*)"/);
  const noindex = /name="robots" content="noindex/.test(html);

  if (!title || title.length > 65) fail(name, `title length ${title?.length}`);
  if (!description || description.length < 70 || description.length > 170) fail(name, `description length ${description?.length}`);
  if ((html.match(/<h1[\s>]/g) ?? []).length !== 1) fail(name, 'must have exactly one <h1>');
  if (!noindex) {
    if (!get(/<link rel="canonical" href="([^"]+)"/)?.startsWith(siteUrl)) fail(name, 'canonical');
    if (!/property="og:image" content="https:/.test(html)) fail(name, 'og:image must be absolute');
  }

  for (const [, json] of html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)) {
    try {
      JSON.parse(json);
    } catch {
      fail(name, 'invalid JSON-LD');
    }
  }
  if (/\sstyle="/.test(html)) fail(name, 'inline style attribute (blocked by the content security policy)');
  if (/https?:\/\/(?!swipr\.app|schema\.org|www\.w3\.org|www\.sitemaps\.org)[^"'\s<]+\.(js|css|png|jpg|woff2?)/.test(html)) {
    fail(name, 'third-party resource');
  }

  // Heading levels shouldn't skip (h2 -> h4).
  let previous = 1;
  for (const [, level] of html.matchAll(/<h([1-6])[\s>]/g)) {
    if (Number(level) > previous + 1) fail(name, `heading jumps h${previous} -> h${level}`);
    previous = Number(level);
  }

  // Internal links and assets resolve.
  for (const [, href] of html.matchAll(/(?:href|src)="(\/[^"#?]*)"/g)) {
    const target = join(out, href);
    const ok = existsSync(target) && (statSync(target).isFile() || existsSync(join(target, 'index.html')));
    if (!ok) fail(name, `broken link ${href}`);
  }
  // In-page anchors exist.
  for (const [, id] of html.matchAll(/href="#([^"]+)"/g)) {
    if (!html.includes(`id="${id}"`)) fail(name, `missing anchor #${id}`);
  }
}

// Every indexable page must be in the sitemap, and every sitemap URL must exist.
// (Next writes 404.html, 404/ and _not-found/ for the same not-found page.)
const indexable = pages.filter((file) => !/name="robots" content="noindex/.test(readFileSync(file, 'utf8')));
const sitemap = readFileSync(join(out, 'sitemap.xml'), 'utf8');
const urls = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
if (urls.length !== indexable.length) {
  fail('sitemap.xml', `${indexable.length} indexable pages but ${urls.length} URLs`);
}
for (const url of urls) {
  if (!existsSync(join(out, url.replace(siteUrl, ''), 'index.html'))) fail('sitemap.xml', `${url} has no page`);
}
if (!readFileSync(join(out, 'robots.txt'), 'utf8').includes('Sitemap:')) fail('robots.txt', 'missing Sitemap');
if (!readFileSync(join(out, '_headers'), 'utf8').includes('sha256-')) fail('_headers', 'no inline script hashes — run scripts/headers.mjs');

console.log(problems ? `\n${problems} problem(s)` : `✓ ${pages.length} pages passed all checks`);
process.exit(problems ? 1 : 0);
