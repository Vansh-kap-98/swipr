import type { Metadata } from 'next';
import { FaqList } from '@/components/Faq';
import { breadcrumbSchema, faqSchema, JsonLd } from '@/components/JsonLd';
import { faqGroups } from '@/lib/faq';
import { site } from '@/lib/site';

export const metadata: Metadata = {
  title: 'FAQ — Deleting Photos, Privacy & Permissions | Swipr',
  description:
    "How Swipr's swipe-to-delete works, recovering photos, iCloud and Google Photos backups, the permissions it needs, and privacy.",
  alternates: { canonical: '/faq/' },
};

export default function FaqPage() {
  return (
    <>
      <JsonLd graph={[faqSchema(faqGroups), breadcrumbSchema('FAQ', '/faq/')]} />

      <section className="page-hero">
        <div className="container narrow center">
          <p className="eyebrow" data-reveal>
            Help
          </p>
          <h1 className="page-hero__title" data-reveal>
            Frequently asked questions
          </h1>
          <p className="section__lead" data-reveal>
            Can&rsquo;t find your answer? Email <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>.
          </p>
        </div>
      </section>

      {faqGroups.map((group) => (
        <section className="section section--tight" aria-labelledby={group.id} key={group.id}>
          <div className="container narrow">
            <h2 id={group.id} className="faq-group__title" data-reveal>
              {group.title}
            </h2>
            <FaqList items={group.items} />
          </div>
        </section>
      ))}
    </>
  );
}
