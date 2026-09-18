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
  title: 'Swipr: Swipe to Clean Up Photos & Videos | Free Cleaner',
  description:
    'Blurry shots, old screenshots, videos you never rewatched. Swipr shows them one at a time so you can swipe them away. Free, no account, nothing leaves your phone.',
  alternates: { canonical: '/' },
};

const features = [
  {
    icon: 'swipe',
    title: 'Swipe to decide',
    body: 'One photo or video at a time, full screen. The card follows your thumb, so deciding is just a flick.',
  },
  {
    icon: 'trash',
    title: 'Nothing deleted by accident',
    body: "Swiping left moves something to Swipr's trash. Nothing is actually gone until you say so.",
  },
  {
    icon: 'undo',
    title: 'Undo, again and again',
    body: 'Swiped too fast? Undo. It slides straight back onto the stack. You can go back fifty swipes if you need to.',
  },
  {
    icon: 'album',
    title: 'By album or by month',
    body: 'Screenshots, Downloads, Camera, or March 2024. Chip away at one corner instead of facing the whole thing.',
  },
  {
    icon: 'zoom',
    title: 'Zoom before you choose',
    body: 'Some shots only look sharp until you open them. Tap for the full thing, or play a video right there.',
  },
  {
    icon: 'stats',
    title: 'See the space you free',
    body: "A running total of what you are about to get back. Videos are where the gigabytes usually hide.",
  },
];

const steps = [
  {
    title: 'Pick what to clean',
    body: 'Start with Screenshots. It is usually the worst offender. Or take a month, an album, or the whole library.',
  },
  {
    title: 'Swipe through',
    body: 'Right to keep, left to delete. Not sure about one? Tap it and look properly. Changed your mind? Undo.',
  },
  {
    title: 'Empty the trash once',
    body: "Nothing goes anywhere while you swipe. It waits in the trash until you look it over and confirm, once.",
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
              Photo &amp; video cleaner for Android &amp; iPhone
            </p>
            <h1 className="hero__title" data-reveal>
              Clean up your camera roll, <span className="text-accent">one swipe at a time.</span>
            </h1>
            <p className="hero__lead" data-reveal>
              You have thousands of photos. Plenty of them you would never miss. Swipr puts them in front of you one at a
              time and you swipe: right to keep, left to delete. Most albums take about five minutes.
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
              <li>Nothing leaves your phone</li>
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
            Everyone means to clean up their photos. Almost nobody does.
          </h2>
          <p className="section__lead" data-reveal>
            Blurry pocket shots. The same sunset fifteen times. Screenshots you needed for about an hour. You know
            they are in there. But long-pressing and selecting your way through a gallery is miserable, so it waits, and
            the library keeps growing. Swipr is quick enough that you actually reach the end.
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
              Quick to use. Careful with your stuff.
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
              Your photos and videos stay on your phone.
            </h2>
            <p className="section__lead" data-reveal>
              There is no account and no server. The Android build does not even ask for internet access, because it
              has nothing to send. What it remembers about your library stays out of your cloud backups too.
            </p>
            <Link className="link-arrow" href="/privacy/" data-reveal>
              Read the privacy policy
            </Link>
          </div>
          <ul className="check-list" data-reveal="right">
            <li>Nothing is uploaded, ever</li>
            <li>No account, no sign-in</li>
            <li>No ads, and no tracking in the app</li>
            <li>It asks for photo and video access, nothing else</li>
            <li>Your phone confirms every deletion</li>
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
            Give it five minutes on one album and see what you get back.
          </p>
          <div data-reveal>
            <DownloadButtons />
          </div>
        </div>
      </section>
    </>
  );
}
