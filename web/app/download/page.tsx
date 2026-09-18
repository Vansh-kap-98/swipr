import type { Metadata } from 'next';
import { DownloadButtons } from '@/components/DownloadButtons';
import { appSchema, breadcrumbSchema, JsonLd } from '@/components/JsonLd';
import { Platforms } from '@/components/Platforms';
import { appVersion } from '@/lib/site';

export const metadata: Metadata = {
  title: 'Download Swipr: Free Photo & Video Cleaner for Android',
  description:
    'Get the free Android APK, with its checksum so you can verify it, the phone versions it runs on, and a plain list of every permission Swipr asks for and why.',
  alternates: { canonical: '/download/' },
};

const permissions = [
  { permission: 'Photos (read)', when: 'Android 13+', why: 'To show your photos in the swipe stack.' },
  { permission: 'Videos (read)', when: 'Android 13+', why: 'To show videos in the same stack as your photos.' },
  {
    permission: 'Selected photos only',
    when: 'Android 14+',
    why: 'Lets you share just some items instead of your whole library.',
  },
  { permission: 'Storage (read)', when: 'Android 8–12', why: "Older Android versions' equivalent of photo and video access." },
  {
    permission: 'Storage (write)',
    when: 'Android 8–9 only',
    why: "Required by those versions to delete the items you've confirmed.",
  },
  {
    permission: 'Photo library (read & write)',
    when: 'iPhone',
    why: 'To show photos and videos, and delete the ones you confirm. Full or limited access both work.',
  },
];

const whatsNew = [
  'Videos are included now: they appear in the stack with their length, and play when you tap',
  'The resume card can be swiped: right to carry on, left to dismiss it',
  'Smoother swiping: the next cards are loaded before you get to them',
];

const alreadyIn = [
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
            Free, on Android and iPhone. Nothing to set up: open it, allow access to your photos, start swiping.
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
            Swipr asks for your photos and videos. That is the lot. Here is each request and what it is for.
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
            <strong>Not requested:</strong> internet, location, camera, contacts, microphone or audio files.
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
          <p className="note" data-reveal>
            <strong>Also in Swipr:</strong>
          </p>
          <ul className="check-list check-list--muted" data-reveal>
            {alreadyIn.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </div>
      </section>
    </>
  );
}
