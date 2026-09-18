import Link from 'next/link';
import { appVersion, site } from '@/lib/site';
import { Logo } from './Logo';

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="container site-footer__grid">
        <div className="site-footer__brand">
          <Link className="brand" href="/" aria-label="Swipr home">
            <Logo />
            <span className="brand__name">Swipr</span>
          </Link>
          <p>Swipe right to keep, left to delete. Free, no account, and your photos never leave your phone.</p>
        </div>
        <nav aria-label="Footer">
          <h2 className="site-footer__heading">App</h2>
          <ul>
            <li>
              <Link href="/download/">Download</Link>
            </li>
            <li>
              <Link href="/features/">Features</Link>
            </li>
            <li>
              <Link href="/faq/">FAQ</Link>
            </li>
          </ul>
        </nav>
        <div>
          <h2 className="site-footer__heading">Trust</h2>
          <ul>
            <li>
              <Link href="/privacy/">Privacy policy</Link>
            </li>
            <li>
              <a href={`mailto:${site.contactEmail}`}>Contact</a>
            </li>
          </ul>
        </div>
      </div>
      <div className="container site-footer__legal">
        <p>
          © {new Date().getFullYear()} Swipr · Version {appVersion}
        </p>
        <p>No cookies and no ads. Anonymous page counts only.</p>
      </div>
    </footer>
  );
}
