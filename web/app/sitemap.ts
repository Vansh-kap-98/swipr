import type { MetadataRoute } from 'next';
import { absolute, buildDate } from '@/lib/site';

const pages: { path: string; priority: number }[] = [
  { path: '/', priority: 1 },
  { path: '/download/', priority: 0.9 },
  { path: '/features/', priority: 0.8 },
  { path: '/faq/', priority: 0.7 },
  { path: '/privacy/', priority: 0.4 },
];

export default function sitemap(): MetadataRoute.Sitemap {
  return pages.map(({ path, priority }) => ({
    url: absolute(path),
    lastModified: buildDate,
    priority,
  }));
}

export const dynamic = "force-static";
