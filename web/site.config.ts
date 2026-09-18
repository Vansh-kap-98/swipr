// Everything about the site that you might want to change lives here.
export const site = {
  name: 'Swipr',
  url: 'https://swipr.app',
  tagline: 'Swipe to clean up your camera roll',
  description:
    'Swipr turns deleting unwanted photos into a fast, Tinder-style swipe. Swipe right to keep, left to delete — free, no account, and your photos never leave your phone.',
  contactEmail: 'hello@swipr.app',
  themeColor: '#0A0A0A',
  locale: 'en_US',
  privacyEffectiveDate: '2026-09-17',
  releaseDate: '2026-09-17',
  requirements: {
    android: 'Android 8.0 or later',
    ios: 'iOS 15 or later',
  },
  stores: {
    // Fill these in once the listings exist; the buttons switch from
    // "Coming soon" to real links automatically.
    googlePlay: null as string | null,
    appStore: null as string | null,
    appStoreId: null as string | null,
  },
  // Direct APK download.
  //
  // `source` is the local file scripts/prepare.mjs measures (size + SHA-256).
  //   app-release.apk                 universal, ~47 MB, installs on any phone
  //   app-arm64-v8a-release.apk       ~16 MB, every phone sold since ~2016
  //   (build both with: flutter build apk --split-per-abi --release)
  //
  // `externalUrl`: leave null to serve the file from this site. Set it to host
  // the APK elsewhere — needed when the site is deployed from git (the APK is
  // not committed) or when the host caps file size (Cloudflare Pages: 25 MB).
  // A GitHub release asset works well:
  //   https://github.com/<you>/<repo>/releases/download/v1.0.0/swipr-1.0.0.apk
  apk: {
    enabled: true,
    source: '../build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
    externalUrl: null as string | null,
  },
} as const;

export type Site = typeof site;
