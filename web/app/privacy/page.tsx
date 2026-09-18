import type { Metadata } from 'next';
import { breadcrumbSchema, JsonLd } from '@/components/JsonLd';
import { site } from '@/lib/site';

export const metadata: Metadata = {
  title: 'Privacy Policy | Swipr',
  description:
    'Swipr collects nothing. No servers, no account, and no analytics in the app. Here is exactly what it can see on your phone, and the little it keeps there.',
  alternates: { canonical: '/privacy/' },
};

export default function PrivacyPage() {
  return (
    <>
      <JsonLd graph={[breadcrumbSchema('Privacy policy', '/privacy/')]} />

      <section className="page-hero page-hero--compact">
        <div className="container narrow">
          <p className="eyebrow" data-reveal>
            Legal
          </p>
          <h1 className="page-hero__title" data-reveal>
            Privacy policy
          </h1>
          <p className="muted" data-reveal>
            Effective {site.privacyEffectiveDate}
          </p>
        </div>
      </section>

      <section className="section section--tight">
        <article className="container narrow prose" data-reveal>
          <div className="callout">
            <p>
              <strong>The short version:</strong> Swipr doesn&rsquo;t collect, send or sell any data. Your photos, videos
              and everything the app knows about them stay on your phone.
            </p>
          </div>

          <h2>Who we are</h2>
          <p>
            This policy covers the Swipr mobile app for Android and iOS (“the app”) and the website at{' '}
            <a href={`${site.url}/`}>{site.url}</a>. If you have questions, contact{' '}
            <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>.
          </p>

          <h2>What the app accesses</h2>
          <p>With your permission, the app accesses your device&rsquo;s photo library in order to:</p>
          <ul>
            <li>show you your photos and videos, their albums, dates, sizes and lengths;</li>
            <li>delete the ones you choose, after you confirm through your device&rsquo;s own system dialog.</li>
          </ul>
          <p>
            You can grant full or limited access (selected photos only) and change it at any time in your device settings.
            The app does not access your location, camera, microphone, contacts or any other data.
          </p>

          <h2>What the app stores</h2>
          <p>
            To work, the app keeps a small database <strong>on your device only</strong>, containing:
          </p>
          <ul>
            <li>
              the device&rsquo;s internal identifiers of the items you&rsquo;ve reviewed, and whether you kept or marked
              them for deletion;
            </li>
            <li>your trash queue, including each item&rsquo;s file size;</li>
            <li>session history and statistics, such as items reviewed, space freed and your streak;</li>
            <li>your settings.</li>
          </ul>
          <p>
            It never stores copies of your photos or videos. This database is excluded from cloud and device backups, and it&rsquo;s
            removed when you uninstall the app.
          </p>

          <h2>What the app shares</h2>
          <p>
            Nothing. The app has no servers, no accounts, no advertising, and no analytics or crash-reporting tools. On
            Android it doesn&rsquo;t request internet access at all.
          </p>
          <p>
            <strong>iCloud Photos:</strong> if your iPhone uses iCloud Photos with “Optimize iPhone Storage”, iOS may
            download a full-quality copy of a photo from your own iCloud account when the app shows it. That transfer is
            handled by Apple&rsquo;s Photos framework between your device and your iCloud account; Swipr doesn&rsquo;t
            receive or send that data anywhere else.
          </p>
          <p>
            <strong>Deletions:</strong> when you delete something, your device removes it from its photo library. If the
            library syncs with a cloud service (for example iCloud Photos), that service applies the deletion under its own
            terms.
          </p>

          <h2>This website</h2>
          <p>
            This website sets no cookies, shows no advertising, and does not track you across other sites. It counts page
            views using our host&rsquo;s privacy-friendly analytics, which records the page visited, rough location
            (country) and device type. It does not store your IP address or build a profile of you, and the data is
            aggregate: we can see that a page was visited, never who visited it.
          </p>
          <p>
            Like any web server, our hosting provider also keeps standard, short-lived request logs for security and
            operations. The app itself contains no analytics of any kind.
          </p>

          <h2>Children</h2>
          <p>
            The app is a general-audience utility and does not knowingly collect personal information from anyone,
            including children under 13.
          </p>

          <h2>Your choices</h2>
          <ul>
            <li>Change or revoke photo access at any time in your device&rsquo;s settings.</li>
            <li>Reset your review history in the app&rsquo;s Settings.</li>
            <li>Delete all of the app&rsquo;s data by uninstalling it.</li>
          </ul>

          <h2>Changes to this policy</h2>
          <p>
            If this policy changes, we&rsquo;ll update the effective date above and, for significant changes, mention it in
            the app&rsquo;s release notes.
          </p>
        </article>
      </section>
    </>
  );
}
