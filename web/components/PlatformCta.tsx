'use client';

import Link from 'next/link';
import { usePlatform } from './usePlatform';

/** Hero call to action, worded for the visitor's device once it's known. */
export function PlatformCta() {
  const platform = usePlatform();
  const { label, href } =
    platform === 'android'
      ? { label: 'Download for Android, free', href: '/download/#android' }
      : platform === 'ios'
        ? { label: 'Get Swipr for iPhone', href: '/download/#ios' }
        : { label: 'Download Swipr, free', href: '/download/' };

  return (
    <Link className="btn btn--primary btn--large" href={href}>
      {label}
    </Link>
  );
}
