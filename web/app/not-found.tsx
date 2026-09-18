import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Page not found | Swipr',
  description: "This page doesn't exist. Head back to Swipr's home page or download the app.",
  robots: { index: false, follow: true },
};

export default function NotFound() {
  return (
    <section className="page-hero not-found">
      <div className="container narrow center">
        <div className="not-found__card" data-reveal aria-hidden="true">
          <span className="visual-stamp visual-stamp--delete">404</span>
        </div>
        <h1 className="page-hero__title" data-reveal>
          This page got swiped left.
        </h1>
        <p className="section__lead" data-reveal>
          We couldn&rsquo;t find what you were looking for.
        </p>
        <div className="hero__cta hero__cta--center" data-reveal>
          <Link className="btn btn--primary" href="/">
            Back to home
          </Link>
          <Link className="btn btn--ghost" href="/download/">
            Download Swipr
          </Link>
        </div>
      </div>
    </section>
  );
}
