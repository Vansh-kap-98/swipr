import type { Metadata } from 'next';
import { DownloadButtons } from '@/components/DownloadButtons';
import { appSchema, breadcrumbSchema, JsonLd } from '@/components/JsonLd';
import { Platforms } from '@/components/Platforms';
import { appVersion } from '@/lib/site';

export const metadata: Metadata = {
  title: 'Download Swipr for Android & iPhone — Free Photo Cleaner App',
  description:
    'Download Swipr, the free swipe-to-delete photo cleaner. Get the Android APK with a SHA-256 checksum, check requirements, and see exactly which permissions the app uses.',
  alternates: { canonical: '/download/' },
};

const permissions = [
  { permission: 'Photos (read)', when: 'Android 13+', why: 'To show your photos one at a time.' },
  {
    permission: 'Selected photos only',
    when: 'Android 14+',
    why: 'Lets you share just some photos instead of your whole library.',
  },
  { permission: 'Storage (read)', when: 'Android 8–12', why: "Older Android versions' equivalent of photo access." },
  {
    permission: 'Storage (write)',
    when: 'Android 8–9 only',
    why: "Required by those versions to delete photos you've confirmed.",
  },
  {
    permission: 'Photo library (read & write)',
    when: 'iPhone',
    why: 'To show photos and delete the ones you confirm. Full or limited access both work.',
  },
];

const whatsNew = [
  'Swipe right to keep, left to delete, with a live green/red preview',
  'Trash queue with restore and one-tap batch delete',
  'Multi-step undo within a session',
  'Browse by album or by month, and resume unfinished sessions',
  'Full-resolution zoom',
  'Space-freed totals, session history and streaks',
];

export default function DownloadPage() {
  return (
    <>
      <JsonLd graph={[appSchema(), breadcrumbSchema('Download', '/download/')]} />

      <section className="page-hero">
        <div className="container narrow center">
          <p className="eyebrow" data-reveal>
            Version {appVersion}
          </p>
          <h1 className="page-hero__title" data-reveal>
            Download Swipr
          </h1>
          <p className="section__lead" data-reveal>
            Free on Android and iPhone. No account, and nothing to set up — open it, pick an album, start swiping.
          </p>
          <div data-reveal>
            <DownloadButtons />
          </div>
        </div>
      </section>

      <section className="section section--tight" aria-labelledby="platforms-title">
        <div className="container">
          <h2 id="platforms-title" className="visually-hidden">
            Platforms
          </h2>
          <Platforms />
        </div>
      </section>

      <section className="section section--surface" aria-labelledby="permissions">
        <div className="container narrow">
          <h2 id="permissions" className="section__title" data-reveal>
            Permissions, explained
          </h2>
          <p className="section__lead" data-reveal>
            Swipr asks for access to your photos, nothing more. Here&rsquo;s exactly what it requests and why.
          </p>
          <div className="table-wrap" data-reveal>
            <table className="perm-table">
              <thead>
                <tr>
                  <th scope="col">Permission</th>
                  <th scope="col">When</th>
                  <th scope="col">Why</th>
                </tr>
              </thead>
              <tbody>
                {permissions.map((row) => (
                  <tr key={row.permission}>
                    <td>{row.permission}</td>
                    <td>{row.when}</td>
                    <td>{row.why}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="note" data-reveal>
            <strong>Not requested:</strong> internet, location, camera, contacts, microphone, video or audio.
          </p>
        </div>
      </section>

      <section className="section" aria-labelledby="new-title">
        <div className="container narrow">
          <h2 id="new-title" className="section__title" data-reveal>
            What&rsquo;s new in {appVersion}
          </h2>
          <ul className="check-list check-list--plain" data-reveal>
            {whatsNew.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </div>
      </section>
    </>
  );
}
