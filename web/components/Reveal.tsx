'use client';

import { useEffect } from 'react';

/**
 * Slides every `data-reveal` element into place as it scrolls into view.
 * Mounted once in the layout, so any element on any page can opt in with the
 * attribute alone — no wrapper component needed.
 */
export function RevealController() {
  useEffect(() => {
    const root = document.documentElement;
    root.classList.add('reveal-ready');

    const targets = [...document.querySelectorAll<HTMLElement>('[data-reveal]')];
    if (!('IntersectionObserver' in window) || window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      targets.forEach((el) => el.classList.add('is-visible'));
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries
          .filter((entry) => entry.isIntersecting)
          .forEach((entry, i) => {
            // Items entering together arrive one after another.
            entry.target.setAttribute('style', `--reveal-delay: ${Math.min(i, 6) * 70}ms`);
            entry.target.classList.add('is-visible');
            observer.unobserve(entry.target);
          });
      },
      { rootMargin: '0px 0px -6% 0px', threshold: 0.06 },
    );
    targets.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  });

  return null;
}
