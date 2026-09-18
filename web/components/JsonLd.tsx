import { absolute, apk, appVersion, site } from '@/lib/site';
import type { FaqGroup } from '@/lib/faq';

type Graph = Record<string, unknown>;

export function appSchema(): Graph {
  return {
    '@type': 'MobileApplication',
    '@id': `${site.url}/#app`,
    name: site.name,
    description: site.description,
    url: `${site.url}/`,
    image: absolute('/img/og-image.png'),
    applicationCategory: 'UtilitiesApplication',
    operatingSystem: 'Android 8.0+, iOS 15+',
    softwareVersion: appVersion,
    datePublished: site.releaseDate,
    offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
    ...(apk.enabled ? { downloadUrl: absolute(apk.url), fileSize: `${apk.sizeMb} MB` } : {}),
  };
}

export function breadcrumbSchema(name: string, path: string): Graph {
  return {
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: `${site.url}/` },
      { '@type': 'ListItem', position: 2, name, item: absolute(path) },
    ],
  };
}

/** Built from the same data the page renders, so the two can't drift apart. */
export function faqSchema(groups: FaqGroup[]): Graph {
  const text = (html: string) => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  return {
    '@type': 'FAQPage',
    mainEntity: groups.flatMap((group) =>
      group.items.map((item) => ({
        '@type': 'Question',
        name: item.q,
        acceptedAnswer: { '@type': 'Answer', text: text(item.a) },
      })),
    ),
  };
}

export function JsonLd({ graph }: { graph: Graph[] }) {
  const json = JSON.stringify({ '@context': 'https://schema.org', '@graph': graph }).replace(/</g, '\\u003c');
  return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: json }} />;
}
