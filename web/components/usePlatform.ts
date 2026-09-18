'use client';

import { useEffect, useState } from 'react';

export type Platform = 'android' | 'ios' | 'other';

/**
 * Which kind of device is visiting. Starts as 'other' so the server-rendered
 * HTML and the first client render match, then updates after mount.
 */
export function usePlatform(): Platform {
  const [platform, setPlatform] = useState<Platform>('other');

  useEffect(() => {
    const ua = navigator.userAgent;
    if (/Android/i.test(ua)) setPlatform('android');
    else if (/iPhone|iPad|iPod/i.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1)) setPlatform('ios');
  }, []);

  return platform;
}
