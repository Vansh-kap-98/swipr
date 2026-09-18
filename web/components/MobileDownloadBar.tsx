'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { apk } from '@/lib/site';
import { usePlatform } from './usePlatform';

/**
 * Phone-only sticky call to action. It slides up once the hero's own button
 * has scrolled away, so the download is always one tap away — the site's
 * visitors are on the device they'd install on.
 */
export function MobileDownloadBar() {
  const platform = usePlatform();
  const pathname = usePathname();
  const [shown, setShown] = useState(false);

  useEffect(() => {
    // The download page is itself the call to action.
    if (pathname === '/download/') {
      setShown(false);
      return;
    }
    // Scroll events already fire at most once per frame, and React ignores a
    // set to the same value — no extra throttling needed, and nothing here
    // depends on animation frames, which browsers pause in background tabs.
    // Appears as soon as the hero's own button starts scrolling away.
    const onScroll = () => setShown(window.scrollY > 200);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, [pathname]);

  // On Android the APK is one tap away; everyone else goes to the download page.
  const directApk = platform === 'android' && apk.enabled ? apk : null;
  const label = directApk
    ? `Download APK · ${directApk.sizeMb} MB`
    : platform === 'ios'
      ? 'Get Swipr for iPhone'
      : 'Download Swipr, free';

  return (
    <div className={`mobile-cta${shown ? ' is-shown' : ''}`} aria-hidden={!shown}>
      <Link
        className="btn btn--primary"
        href={directApk ? directApk.url : platform === 'ios' ? '/download/#ios' : '/download/'}
        {...(directApk ? { download: '' } : {})}
        tabIndex={shown ? undefined : -1}
      >
        {label}
      </Link>
    </div>
  );
}
