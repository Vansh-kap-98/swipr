# swipr.app website (Next.js)

The Swipr download site: Next.js 16 App Router with React 19, built as a **static export**. Every page ships finished HTML, so search engines and people with JavaScript disabled see the full content. No cookies, analytics or third-party requests. Same palette as the app (no purple), and all motion is sliding.

```bash
npm install
npm run dev      # http://localhost:4174
npm run build    # writes out/ and regenerates out/_headers
npm run check    # SEO, links, JSON-LD and CSP checks on out/
npm run images   # re-render the icons and og-image.png (needs Chrome)
```

Deploy the `out/` folder to any static host.

## Before going live

1. **Domain:** set `url` in [site.config.ts](site.config.ts). Canonical URLs, Open Graph tags, the sitemap and structured data all follow it.
2. **Contact:** set `contactEmail`.
3. **APK signing:** the Flutter template signs release builds with the debug key. [Set up a release keystore](https://docs.flutter.dev/deployment/android#signing-the-app) before publishing the APK — users can't update from a debug-signed install to a properly signed one without uninstalling, which deletes their data. `flutter build apk --split-per-abi` gives a much smaller arm64 download; point `apk.source` at it.
4. **Store listings:** fill in `stores.googlePlay`, `stores.appStore` and `stores.appStoreId`. Buttons switch from "Coming soon" to links automatically, and iOS Safari shows its Smart App Banner.
5. **Hosting:** `out/_headers` (Netlify / Cloudflare Pages format) carries the content security policy, security headers and caching. On other hosts, copy those rules into their config. Serve `404.html` as the not-found page.
6. **Search Console:** submit `/sitemap.xml` to Google Search Console and Bing Webmaster Tools.

## Structure

```
site.config.ts        domain, contact, store links, requirements, APK source
app/
  layout.tsx          <head> metadata, header/footer, reveal controller
  page.tsx            home
  download/page.tsx   APK, checksum, requirements, permissions
  features/page.tsx   feature detail + comparison table
  faq/page.tsx        renders lib/faq.ts
  privacy/page.tsx    privacy policy
  not-found.tsx       404 (exported as 404.html)
  sitemap.ts          sitemap.xml        robots.ts -> robots.txt
  globals.css         the whole stylesheet
components/           Header, Footer, PhoneDemo, Platforms, DownloadButtons, …
lib/site.ts           config + build info (version, APK size/checksum)
lib/faq.ts            FAQ content — the page and its FAQ schema share it
scripts/prepare.mjs   pre-build: version, APK copy + checksum, manifest, favicon
scripts/headers.mjs   post-build: CSP hashes for Next's inline scripts
scripts/check.mjs     pre-deploy checks
```

## Notes

- **The phone demo** (`components/PhoneDemo.tsx`) is a client component. React renders the three visible cards; dragging and the animations write transforms straight to the DOM, so nothing re-renders per frame. It has the same physics as the app: a 35%-of-width or fast-flick threshold, a critically damped spring back to center, and thrown cards keeping the finger's speed.
- **No inline `style` attributes.** The content security policy blocks them, so dynamic styling goes through the CSSOM (`el.style.setProperty`). `scripts/check.mjs` fails the build if one appears.
- **Reveal animations** are driven by `data-reveal` attributes and one observer in `components/Reveal.tsx`. With `prefers-reduced-motion`, or no JavaScript, everything is simply visible.
- **Keep it accurate.** Claims about permissions, "nothing leaves your phone", requirements and undo limits must match the app. Don't add ratings, review counts or testimonials unless they're real — Google penalizes invented review markup.

The earlier dependency-free version of this site is in [`../website`](../website). It's no longer used; delete it once you're happy with this one.
