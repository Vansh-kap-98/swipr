'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Logo } from './Logo';

const links = [
  { href: '/', label: 'Home' },
  { href: '/features/', label: 'Features' },
  { href: '/faq/', label: 'FAQ' },
];

export function Header() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  // Only collapse the menu into a button once this component is running, so a
  // failed script leaves a plain, usable list of links.
  useEffect(() => {
    document.documentElement.classList.add('nav-ready');
  }, []);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false);
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open]);

  const current = (href: string) => (pathname === href ? 'page' : undefined);

  return (
    <header className="site-header">
      <div className="container site-header__inner">
        <Link className="brand" href="/" aria-label="Swipr home">
          <Logo />
          <span className="brand__name">Swipr</span>
        </Link>
        <button
          className="nav-toggle"
          type="button"
          aria-expanded={open}
          aria-controls="site-nav"
          onClick={() => setOpen((v) => !v)}
        >
          <span className="nav-toggle__icon" aria-hidden="true">
            <span className="nav-toggle__menu" />
            <span className="nav-toggle__close">✕</span>
          </span>
          <span className="visually-hidden">Menu</span>
        </button>
        <nav id="site-nav" className={`site-nav${open ? ' is-open' : ''}`} aria-label="Main">
          <ul onClick={() => setOpen(false)}>
            {links.map((link) => (
              <li key={link.href}>
                <Link href={link.href} aria-current={current(link.href)}>
                  {link.label}
                </Link>
              </li>
            ))}
            <li>
              <Link className="btn btn--primary btn--small" href="/download/" aria-current={current('/download/')}>
                Download
              </Link>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
}
