import buildInfo from './build-info.json';
import { site } from '@/site.config';

export { site };

export type ApkInfo =
  | { enabled: false }
  | { enabled: true; url: string; fileName: string; sizeMb: string; sha256: string };

export const appVersion: string = buildInfo.version;
export const apk = buildInfo.apk as ApkInfo;
export const buildDate: string = buildInfo.builtAt;

export const stores = {
  googlePlay: site.stores.googlePlay,
  appStore: site.stores.appStore,
};

/** Absolute URL, used for canonical links, Open Graph tags and the sitemap. */
export const absolute = (path: string) => `${site.url}${path}`;
