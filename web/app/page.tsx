import type { Metadata } from 'next';
import Link from 'next/link';
import { DownloadButtons } from '@/components/DownloadButtons';
import { FaqList } from '@/components/Faq';
import { appSchema, JsonLd } from '@/components/JsonLd';
import { PhoneDemo } from '@/components/PhoneDemo';
import { PlatformCta } from '@/components/PlatformCta';
import { homeFaq } from '@/lib/faq';
import { site } from '@/lib/site';

export const metadata: Metadata = {
  title: 'Swipr — Swipe to Clean Up Your Camera Roll | Free Photo Cleaner',
  description:
    'Delete blurry shots, screenshots and duplicates in minutes. Swipr shows your photos one at a time: swipe right to keep, left to delete. Free, no account, 100% on-device.',
  alternates: { canonical: '/' },
};

const features = [
  {
    icon: 'swipe',
    title: 'Swipe to decide',
    body: 'One photo or video at a time, full screen. The card follows your finger, so a decision is a flick.',
  },
  {
    icon: 'trash',
    title: 'Nothing deleted by accident',
    body: "Swiping left only adds a photo to Swipr's trash. Nothing leaves your phone until you empty it.",
  },
  {
    icon: 'undo',
    title: 'Undo, again and again',
    body: 'Take back your last swipe — or the last fifty. The photo slides right back onto the stack.',
  },
  {
    icon: 'album',
    title: 'By album or by month',
    body: 'Screenshots, Downloads, Camera, or “March 2024”. Clean up one small part of your library at a time.',
  },
  {
    icon: 'zoom',
    title: 'Zoom before you choose',
    body: 'Tap to see a photo at full resolution, or play a video, before you decide.',
  },
  {
    icon: 'stats',
    title: 'See the space you free',
    body: "A running total shows how much space you'll get back, plus sessions, photos reviewed and your streak.",
  },
];

const steps = [
  {
    title: 'Pick what to clean',
    body: 'Choose an album like Screenshots or WhatsApp, a month, or your whole library. Small albums are a quick win.',
  },
  {
    title: 'Swipe through',
    body: 'Right to keep, left to delete. Tap to zoom in when you need a closer look. Changed your mind? Undo.',
  },
  {
    title: 'Empty the trash once',
    body: "Photos you swiped away wait in Swipr's trash. Review them, then delete them all with a single confirmation.",
  },
];

export default function HomePage() {
  return (
    <>
      <JsonLd
        graph={[
          { '@type': 'WebSite', '@id': `${site.url}/#website`, name: site.name, url: `${site.url}/`, inLanguage: 'en' },
          appSchema(),
        ]}
      />

      <section className="hero">
        <div className="container hero__grid">
          <div className="hero__copy">
            <p className="eyebrow" data-reveal>
              Photo cleaner for Android &amp; iPhone
            </p>
            <h1 className="hero__title" data-reveal>
              Clean up your camera roll, <span className="text-accent">one swipe at a time.</span>
            </h1>
            <p className="hero__lead" data-reveal>
              Thousands of photos, hundreds you don&rsquo;t need. Swipr shows them one by one — swipe right to keep, left
              to delete. Clearing out a whole album takes minutes, not an afternoon.
            </p>
            <div className="hero__cta" data-reveal>
              <PlatformCta />
              <a className="btn btn--ghost btn--large" href="#how-it-works">
                See how it works
              </a>
            </div>
            <ul className="trust-list" data-reveal>
              <li>Free</li>
              <li>No account</li>
              <li>Photos never leave your phone</li>
            </ul>
          </div>
          <div className="hero__demo" data-reveal="right">
            <PhoneDemo />
          </div>
        </div>
      </section>

      <section className="section section--tight" aria-labelledby="problem-title">
        <div className="container narrow center">
          <h2 id="problem-title" className="section__title" data-reveal>
            Your gallery keeps growing. Cleaning it never happens.
          </h2>
          <p className="section__lead" data-reveal>
            Blurry pocket shots, fifteen versions of the same sunset, screenshots you needed once. Deleting them the usual
            way — long-press, select, scroll, confirm — is so slow that nobody does it. Swipr makes it fast enough to
            actually finish.
          </p>
        </div>
      </section>

      <section id="how-it-works" className="section" aria-labelledby="how-title">
        <div className="container">
          <h2 id="how-title" className="section__title center" data-reveal>
            How it works
          </h2>
          <ol className="steps">
            {steps.map((step, i) => (
              <li className="step" key={step.title} data-reveal>
                <span className="step__num" aria-hidden="true">
                  {i + 1}
                </span>
                <h3>{step.title}</h3>
                <p>{step.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="section section--surface" aria-labelledby="features-title">
        <div className="container">
          <div className="section__head">
            <h2 id="features-title" className="section__title" data-reveal>
              Built for speed. Careful with your photos.
            </h2>
            <Link className="link-arrow" href="/features/" data-reveal>
              All features
            </Link>
          </div>
          <ul className="feature-grid">
            {features.map((feature) => (
              <li className="feature" key={feature.title} data-reveal>
                <span className={`feature__icon feature__icon--${feature.icon}`} aria-hidden="true" />
                <h3>{feature.title}</h3>
                <p>{feature.body}</p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="section" aria-labelledby="privacy-title">
        <div className="container privacy-band">
          <div className="privacy-band__copy">
            <p className="eyebrow" data-reveal>
              Private by design
            </p>
            <h2 id="privacy-title" className="section__title" data-reveal>
              Your photos stay on your phone. All of them.
            </h2>
            <p className="section__lead" data-reveal>
              Swipr has no servers and no account, and it collects no analytics. On Android it doesn&rsquo;t even ask for
              internet access. Its own data is kept out of cloud backups too.
            </p>
            <Link className="link-arrow" href="/privacy/" data-reveal>
              Read the privacy policy
            </Link>
          </div>
          <ul className="check-list" data-reveal="right">
            <li>No uploads, no cloud processing</li>
            <li>No account or sign-in</li>
            <li>No ads, analytics or trackers</li>
            <li>Only the photo permission it needs</li>
            <li>Every delete confirmed by your phone</li>
          </ul>
        </div>
      </section>

      <section className="section section--surface" aria-labelledby="faq-title">
        <div className="container narrow">
          <div className="section__head">
            <h2 id="faq-title" className="section__title" data-reveal>
              Questions
            </h2>
            <Link className="link-arrow" href="/faq/" data-reveal>
              All FAQs
            </Link>
          </div>
          <FaqList items={homeFaq} />
        </div>
      </section>

      <section className="section cta-band" aria-labelledby="cta-title">
        <div className="container center">
          <h2 id="cta-title" className="cta-band__title" data-reveal>
            Get your storage back tonight.
          </h2>
          <p className="section__lead" data-reveal>
            Pick one album, swipe for five minutes, and see how much space you free.
          </p>
          <div data-reveal>
            <DownloadButtons />
          </div>
        </div>
      </section>
    </>
  );
}
