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
  // Direct APK download. `source` is resolved by scripts/prepare.mjs, which
  // copies the file into public/downloads and records its size and checksum.
  apk: {
    enabled: true,
    source: '../build/app/outputs/flutter-apk/app-release.apk',
  },
} as const;

export type Site = typeof site;
