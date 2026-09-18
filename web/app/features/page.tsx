import type { Metadata } from 'next';
import { DownloadButtons } from '@/components/DownloadButtons';
import { breadcrumbSchema, JsonLd } from '@/components/JsonLd';

export const metadata: Metadata = {
  title: 'Features: Swipe to Delete Photos & Videos | Swipr',
  description:
    'Swipe to delete photos and videos, a trash you can undo, album and month views, zoom, playback and stats. Here is everything Swipr does, in detail.',
  alternates: { canonical: '/features/' },
};

const comparison = [
  { row: 'Delete something', gallery: 'Long-press, select, delete, confirm', swipr: 'One swipe' },
  { row: 'See each one properly', gallery: 'Tiny grid thumbnails', swipr: 'Full screen, one at a time' },
  { row: 'Confirmations', gallery: 'Every batch you select', swipr: 'Once, when you empty the trash' },
  { row: 'Change your mind', gallery: 'Dig through “Recently deleted”', swipr: 'Undo, or restore from the trash' },
  { row: 'Track your progress', gallery: 'Nothing to track it with', swipr: 'Progress bar, space freed, streaks' },
];

export default function FeaturesPage() {
  return (
    <>
      <JsonLd graph={[breadcrumbSchema('Features', '/features/')]} />

      <section className="page-hero">
        <div className="container narrow center">
          <p className="eyebrow" data-reveal>
            Features
          </p>
          <h1 className="page-hero__title" data-reveal>
            Everything it does, and nothing it doesn&rsquo;t
          </h1>
          <p className="section__lead" data-reveal>
            It does one job. Here is the whole of it.
          </p>
        </div>
      </section>

      <section className="section section--tight">
        <div className="container feature-rows">
          <article className="feature-row" data-reveal>
            <div className="feature-row__visual visual-swipe" aria-hidden="true">
              <span className="visual-card visual-card--back" />
              <span className="visual-card visual-card--front scene-ocean">
                <span className="visual-stamp visual-stamp--keep">KEEP</span>
              </span>
            </div>
            <div className="feature-row__copy">
              <h2>Swipe to decide</h2>
              <p>
                Photos and videos come up full screen, one at a time, with the next few stacked behind. Drag right to
                keep, left to delete. The card tilts as it follows your thumb and turns green or red before you let go.
                Let go too early and it springs back, so a stray swipe costs you nothing.
              </p>
              <p>Prefer tapping? The ✕ and ✓ buttons do exactly the same thing.</p>
            </div>
          </article>

          <article className="feature-row feature-row--flip" data-reveal>
            <div className="feature-row__visual visual-trash" aria-hidden="true">
              <span className="visual-pill">🗑 14 items · 1.2 GB</span>
              <span className="visual-grid">
                <i />
                <i />
                <i />
                <i />
                <i />
                <i />
              </span>
            </div>
            <div className="feature-row__copy">
              <h2>A trash you can trust</h2>
              <p>
                Swiping left deletes nothing. It drops the item into Swipr&rsquo;s trash, and a counter keeps track of
                how much is waiting there. Two long videos can be a gigabyte between them.
              </p>
              <p>
                Open the trash and tap anything to get it back. When you are done second-guessing yourself, empty it.
                Your phone asks once, for the whole lot, instead of once per item.
              </p>
            </div>
          </article>

          <article className="feature-row" data-reveal>
            <div className="feature-row__visual visual-undo" aria-hidden="true">
              <span className="visual-card visual-card--front scene-forest visual-card--return" />
              <span className="visual-undo-btn">↺</span>
            </div>
            <div className="feature-row__copy">
              <h2>Undo as many times as you need</h2>
              <p>
                Swiped too fast? Undo slides the last one back onto the stack. Keep tapping to keep going back, up to
                200 swipes if you set it that high.
              </p>
            </div>
          </article>

          <article className="feature-row feature-row--flip" data-reveal>
            <div className="feature-row__visual visual-albums" aria-hidden="true">
              <span className="visual-album scene-screens">
                <b>Screenshots</b>
              </span>
              <span className="visual-album scene-sunset">
                <b>March 2024</b>
              </span>
              <span className="visual-album scene-ocean">
                <b>WhatsApp</b>
              </span>
              <span className="visual-album scene-forest">
                <b>Camera</b>
              </span>
            </div>
            <div className="feature-row__copy">
              <h2>Clean up one piece at a time</h2>
              <p>
                Take one album at a time, like Screenshots or WhatsApp, or pick a month out of your library. Anything
                you have already been through stays gone from the stack.
              </p>
              <p>
                Stopped halfway? Swipr remembers, and a “Continue swiping” card takes you back to where you left off.
              </p>
            </div>
          </article>

          <article className="feature-row" data-reveal>
            <div className="feature-row__visual visual-zoom" aria-hidden="true">
              <span className="visual-card visual-card--front scene-blur" />
              <span className="visual-lens" />
            </div>
            <div className="feature-row__copy">
              <h2>Zoom in before you choose</h2>
              <p>
                Plenty of shots look fine until you open them properly. Tap one for full resolution, pinch to zoom, then
                drag down to get back to swiping.
              </p>
              <p>Videos play right there too, so you can check one before deciding. They&rsquo;re often the biggest files on your phone.</p>
            </div>
          </article>

          <article className="feature-row feature-row--flip" data-reveal>
            <div className="feature-row__visual visual-stats" aria-hidden="true">
              <span className="visual-stat visual-stat--big">
                <small>Space freed</small>2.4 GB
              </span>
              <span className="visual-stat">
                <small>Streak</small>6 days
              </span>
              <span className="visual-stat">
                <small>Reviewed</small>3,812
              </span>
            </div>
            <div className="feature-row__copy">
              <h2>Watch the space come back</h2>
              <p>
                Every session ends with what you kept, what you marked, and the space you are about to get back. The
                stats screen adds it all up, including how many days in a row you have bothered.
              </p>
            </div>
          </article>
        </div>
      </section>

      <section className="section section--surface" aria-labelledby="compare-title">
        <div className="container narrow">
          <h2 id="compare-title" className="section__title" data-reveal>
            Swipr vs. your gallery app
          </h2>
          <div className="table-wrap" data-reveal>
            <table className="compare-table">
              <thead>
                <tr>
                  <th scope="col" />
                  <th scope="col">Built-in gallery</th>
                  <th scope="col">Swipr</th>
                </tr>
              </thead>
              <tbody>
                {comparison.map((row) => (
                  <tr key={row.row}>
                    <th scope="row">{row.row}</th>
                    <td>{row.gallery}</td>
                    <td>{row.swipr}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="section" aria-labelledby="roadmap-title">
        <div className="container narrow">
          <h2 id="roadmap-title" className="section__title" data-reveal>
            Not in version 1 (yet)
          </h2>
          <p className="section__lead" data-reveal>
            Better you know before you download. These are on the list for later:
          </p>
          <ul className="check-list check-list--muted" data-reveal>
            <li>Finding duplicate and near-identical photos automatically</li>
            <li>Checking something is backed up before you delete it</li>
            <li>Syncing your progress between devices</li>
          </ul>
        </div>
      </section>

      <section className="section cta-band" aria-labelledby="cta-title">
        <div className="container center">
          <h2 id="cta-title" className="cta-band__title" data-reveal>
            Ready to swipe?
          </h2>
          <div data-reveal>
            <DownloadButtons />
          </div>
        </div>
      </section>
    </>
  );
}
