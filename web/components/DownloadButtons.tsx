import { apk, stores } from '@/lib/site';

function PlayIcon() {
  return (
    <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24">
      <path fill="currentColor" d="M4 3.5v17a1 1 0 0 0 1.5.86l14.72-8.5a1 1 0 0 0 0-1.72L5.5 2.64A1 1 0 0 0 4 3.5Z" />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg aria-hidden="true" width="24" height="24" viewBox="0 0 24 24">
      <rect x="6" y="2" width="12" height="20" rx="3" fill="none" stroke="currentColor" strokeWidth="2" />
      <circle cx="12" cy="18" r="1.2" fill="currentColor" />
    </svg>
  );
}

export function DownloadButtons() {
  return (
    <div className="store-buttons">
      {apk.enabled && (
        <a className="store-btn store-btn--primary" href={apk.url} download>
          <svg aria-hidden="true" width="26" height="26" viewBox="0 0 24 24">
            <path
              fill="currentColor"
              d="M12 3a1 1 0 0 1 1 1v9.59l3.3-3.3a1 1 0 1 1 1.4 1.42l-5 5a1 1 0 0 1-1.4 0l-5-5a1 1 0 1 1 1.4-1.42L11 13.6V4a1 1 0 0 1 1-1Zm-7 15a1 1 0 0 1 1 1v1h12v-1a1 1 0 1 1 2 0v2a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-2a1 1 0 0 1 1-1Z"
            />
          </svg>
          <span>
            <small>Android · {apk.sizeMb} MB</small>Download APK
          </span>
        </a>
      )}

      {stores.googlePlay ? (
        <a className="store-btn" href={stores.googlePlay} rel="noopener">
          <PlayIcon />
          <span>
            <small>Get it on</small>Google Play
          </span>
        </a>
      ) : (
        <span className="store-btn store-btn--soon" aria-disabled="true">
          <PlayIcon />
          <span>
            <small>Coming soon to</small>Google Play
          </span>
        </span>
      )}

      {stores.appStore ? (
        <a className="store-btn" href={stores.appStore} rel="noopener">
          <AppleIcon />
          <span>
            <small>Download on the</small>App Store
          </span>
        </a>
      ) : (
        <span className="store-btn store-btn--soon" aria-disabled="true">
          <AppleIcon />
          <span>
            <small>Coming soon to the</small>App Store
          </span>
        </span>
      )}
    </div>
  );
}
