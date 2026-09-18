import { Analytics } from '@vercel/analytics/next';
import type { Metadata, Viewport } from 'next';
import { Footer } from '@/components/Footer';
import { Header } from '@/components/Header';
import { MobileDownloadBar } from '@/components/MobileDownloadBar';
import { site, stores } from '@/lib/site';
import { site as config } from '@/site.config';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL(site.url),
  title: `${site.name} — ${site.tagline}`,
  description: site.description,
  applicationName: site.name,
  alternates: { canonical: '/' },
  openGraph: {
    type: 'website',
    siteName: site.name,
    locale: site.locale,
    images: [{ url: '/img/og-image.png', width: 1200, height: 630, alt: 'Swipr — swipe right to keep, left to delete' }],
  },
  twitter: { card: 'summary_large_image', images: ['/img/og-image.png'] },
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: '32x32' },
      { url: '/img/favicon.svg', type: 'image/svg+xml' },
    ],
    apple: '/img/apple-touch-icon.png',
  },
  manifest: '/site.webmanifest',
  // iOS Safari's Smart App Banner, once the App Store listing exists.
  ...(stores.appStore && config.stores.appStoreId
    ? { appleWebApp: { capable: false }, other: { 'apple-itunes-app': `app-id=${config.stores.appStoreId}` } }
    : {}),
};

export const viewport: Viewport = {
  themeColor: site.themeColor,
  colorScheme: 'dark',
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <a className="skip-link" href="#main">
          Skip to content
        </a>
        <Header />
        <main id="main">{children}</main>
        <Footer />
        <MobileDownloadBar />
        {/* Cookieless page counts. No personal data, no cross-site tracking;
            the footer and privacy policy say so plainly. */}
        <Analytics />
      </body>
    </html>
  );
}
