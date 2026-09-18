'use client';

import { CopyButton } from './CopyButton';
import { usePlatform } from './usePlatform';
import { apk, site, stores } from '@/lib/site';

/** The two platform cards. The visitor's own platform is highlighted and moved first. */
export function Platforms() {
  const platform = usePlatform();

  const android = (
    <article
      id="android"
      key="android"
      className={`platform-card${platform === 'android' ? ' is-yours' : ''}`}
      data-reveal
    >
      <header className="platform-card__head">
        <h3>Android</h3>
        <span className="platform-card__req">{site.requirements.android}</span>
      </header>
      {apk.enabled ? (
        <>
          <p>
            Install Swipr directly with the APK below.{' '}
            {stores.googlePlay ? (
              <>
                Or get it from{' '}
                <a href={stores.googlePlay} rel="noopener">
                  Google Play
                </a>
                .
              </>
            ) : (
              'The Google Play listing is coming soon.'
            )}
          </p>
          <a className="btn btn--primary" href={apk.url} download>
            Download {apk.fileName} ({apk.sizeMb} MB)
          </a>
          <div className="checksum">
            <span className="checksum__label" id="sha-label">
              SHA-256
            </span>
            <code className="checksum__value" aria-labelledby="sha-label">
              {apk.sha256}
            </code>
            <CopyButton value={apk.sha256} />
          </div>
          <h4>Installing the APK</h4>
          <ol className="numbered">
            <li>Download the file on your Android phone.</li>
            <li>Open it from your notifications or the Downloads app.</li>
            <li>
              If asked, allow your browser or file manager to <em>install unknown apps</em>.
            </li>
            <li>
              Tap <strong>Install</strong>, then open Swipr and allow photo access.
            </li>
          </ol>
        </>
      ) : (
        <p>
          {stores.googlePlay ? (
            <>
              Get Swipr from{' '}
              <a href={stores.googlePlay} rel="noopener">
                Google Play
              </a>
              .
            </>
          ) : (
            'Swipr for Android is coming soon to Google Play.'
          )}
        </p>
      )}
    </article>
  );

  const ios = (
    <article id="ios" key="ios" className={`platform-card${platform === 'ios' ? ' is-yours' : ''}`} data-reveal>
      <header className="platform-card__head">
        <h3>iPhone</h3>
        <span className="platform-card__req">{site.requirements.ios}</span>
      </header>
      {stores.appStore ? (
        <>
          <p>Get Swipr from the App Store.</p>
          <a className="btn btn--primary" href={stores.appStore} rel="noopener">
            Open in the App Store
          </a>
        </>
      ) : (
        <>
          <p>
            Swipr for iPhone is on its way to the App Store. Apple only allows iPhone apps to be installed from the App
            Store, so there&rsquo;s no direct download.
          </p>
          <span className="btn btn--ghost is-disabled" aria-disabled="true">
            Coming soon
          </span>
        </>
      )}
    </article>
  );

  return <div className="platforms">{platform === 'ios' ? [ios, android] : [android, ios]}</div>;
}
