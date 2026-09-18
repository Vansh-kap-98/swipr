import type { Metadata } from 'next';
import { DownloadButtons } from '@/components/DownloadButtons';
import { breadcrumbSchema, JsonLd } from '@/components/JsonLd';

export const metadata: Metadata = {
  title: 'Features: Swipe to Delete, Undo & Safe Trash | Swipr',
  description:
    'Swipe-to-delete, a restorable trash with one-tap batch delete, multi-step undo, album and month views, zoom and stats. See what Swipr does.',
  alternates: { canonical: '/features/' },
};

const comparison = [
  { row: 'Delete a photo', gallery: 'Long-press, select, delete, confirm', swipr: 'One swipe' },
  { row: 'See each photo properly', gallery: 'Tiny grid thumbnails', swipr: 'Full screen, one at a time' },
  { row: 'Confirmations', gallery: 'Every batch you select', swipr: 'Once, when you empty the trash' },
  { row: 'Change your mind', gallery: 'Dig through “Recently deleted”', swipr: 'Undo, or restore from the trash' },
  { row: 'Track your progress', gallery: '—', swipr: 'Progress bar, space freed, streaks' },
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
            Everything you need to clear out your photos — and nothing that slows you down
          </h1>
          <p className="section__lead" data-reveal>
            Swipr does one job: turning a gallery cleanup you keep putting off into a few focused minutes.
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
                Photos and videos appear full screen, one at a time, with the next ones stacked behind. Drag right to keep
                or left to delete — the card tilts as you move and turns green or red before you let go. A short drag springs back, so
                you never decide by accident.
              </p>
              <p>Prefer tapping? The ✕ and ✓ buttons do exactly the same thing.</p>
            </div>
          </article>

          <article className="feature-row feature-row--flip" data-reveal>
            <div className="feature-row__visual visual-trash" aria-hidden="true">
              <span className="visual-pill">🗑 14 photos · 128 MB</span>
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
                Swiping left doesn&rsquo;t delete anything. The photo goes into Swipr&rsquo;s trash, and a counter shows
                how many photos and how much space are waiting.
              </p>
              <p>
                Open the trash to restore anything with a tap. When you&rsquo;re ready, empty it — your phone asks you to
                confirm once for the whole batch, not once per photo.
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
                Swiped too fast? Undo slides the last photo back onto the stack. Keep tapping to go further back — up to
                200 steps, depending on your settings.
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
                Pick a single album — Screenshots, Downloads, WhatsApp — or a month from your library&rsquo;s timeline.
                Photos you&rsquo;ve already reviewed don&rsquo;t show up again.
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
                Blur and missed focus are easy to miss on a small preview. Tap any photo to open it at full resolution,
                pinch to zoom, and drag down to go back.
              </p>
              <p>Videos play right there too, so you can check one before deciding — they&rsquo;re often the biggest files on your phone.</p>
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
                Every session ends with a summary of photos kept, marked and the space you&rsquo;re about to free. Your
                stats add up the total freed, the photos reviewed and your current streak.
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
            We&rsquo;d rather tell you up front. These are on the list for later versions:
          </p>
          <ul className="check-list check-list--muted" data-reveal>
            <li>Finding duplicate and near-identical photos automatically</li>
            <li>Checking a photo is backed up before you delete it</li>
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
