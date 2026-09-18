import { site } from './site';

export type FaqItem = { q: string; a: string };
export type FaqGroup = { title: string; id: string; items: FaqItem[] };

/** Answers may contain simple HTML links; the FAQ schema strips the tags. */
export const faqGroups: FaqGroup[] = [
  {
    title: 'The basics',
    id: 'faq-basics',
    items: [
      {
        q: 'What is Swipr?',
        a: 'Swipr is a photo cleaner for Android and iPhone. It shows your photos one at a time — swipe right to keep a photo, left to delete it — so you can clear out a cluttered gallery quickly.',
      },
      { q: 'Is Swipr free?', a: 'Yes. There are no ads, subscriptions or in-app purchases.' },
      {
        q: 'Do I need to create an account?',
        a: 'No. There&rsquo;s no sign-up or login. Open the app, allow photo access and start swiping.',
      },
      {
        q: 'Which phones does Swipr work on?',
        a: `Android phones running ${site.requirements.android}, and iPhones running ${site.requirements.ios}.`,
      },
      {
        q: 'Does Swipr work with videos?',
        a: 'Yes. Videos appear in the stack alongside your photos, with their length on the thumbnail. Tap one to play it before you decide, and clearing out a few long videos frees a lot of space.',
      },
    ],
  },
  {
    title: 'Deleting photos',
    id: 'faq-deleting',
    items: [
      {
        q: 'Does swiping left delete the photo immediately?',
        a: 'No. Swiping left adds the photo to Swipr&rsquo;s trash. Nothing is removed from your phone until you open the trash, tap Empty Trash and confirm.',
      },
      {
        q: 'Can I get a photo back after swiping left?',
        a: 'Yes. Tap Undo to bring back recent swipes, or open the trash and tap any photo to restore it. After you empty the trash, deleted photos follow your phone&rsquo;s normal rules — for example, they may appear in the Photos app&rsquo;s &ldquo;Recently Deleted&rdquo; album for a while.',
      },
      {
        q: 'Why does my phone ask me to confirm the deletion?',
        a: 'Android and iOS don&rsquo;t let any app delete your photos silently — your phone always shows its own confirmation. Swipr groups everything in the trash into one request, so you confirm once instead of once per photo. (Android 10 is an exception and may ask for each photo.)',
      },
      {
        q: 'What happens if I cancel the confirmation?',
        a: 'Nothing is deleted and your trash stays exactly as it was, so you can try again later.',
      },
      {
        q: 'Will deleting in Swipr remove photos from iCloud or Google Photos?',
        a: 'Swipr deletes photos through your phone&rsquo;s own photo library, exactly like deleting them in your gallery app. If your library syncs with iCloud Photos, the deletion syncs too. Google Photos backups have their own settings, so check them if you want to keep a backup copy.',
      },
      {
        q: 'Will I see the same photos again next time?',
        a: 'No. Swipr remembers which photos you&rsquo;ve reviewed and skips them. You can reset this in Settings if you want to go through everything again.',
      },
    ],
  },
  {
    title: 'Privacy & permissions',
    id: 'faq-privacy',
    items: [
      {
        q: 'Are my photos uploaded anywhere?',
        a: 'No. Swipr has no servers. Everything happens on your phone, and the Android app doesn&rsquo;t even request internet access.',
      },
      {
        q: 'What permissions does Swipr need?',
        a: 'Only access to your photos and videos, so it can show them to you and delete the ones you confirm. It doesn&rsquo;t ask for location, camera, contacts, microphone or internet. The <a href="/download/#permissions">download page</a> lists each permission by Android version.',
      },
      {
        q: 'Can I give Swipr access to only some photos?',
        a: 'Yes. On iPhone and on Android 14 or later you can choose &ldquo;Limited&rdquo; or &ldquo;Selected photos&rdquo; access. Swipr will only show those photos, and you can add more at any time.',
      },
      {
        q: 'Does Swipr collect any data?',
        a: 'No. There are no analytics, ads or crash reporters. Swipr stores its own records — which photos you reviewed, your trash and your stats — only on your phone. See the <a href="/privacy/">privacy policy</a>.',
      },
    ],
  },
  {
    title: 'Installing',
    id: 'faq-install',
    items: [
      {
        q: 'Is the Android APK safe to install?',
        a: 'Download it only from this website. The download page shows the file&rsquo;s SHA-256 checksum so you can check it matches. Android may warn you about installing apps from outside Google Play — that&rsquo;s normal for any direct download.',
      },
      {
        q: 'Why can&rsquo;t I download Swipr directly on iPhone?',
        a: 'Apple only allows iPhone apps to be installed through the App Store. Swipr for iPhone will be available there.',
      },
    ],
  },
];

/** The few questions shown on the home page. */
export const homeFaq: FaqItem[] = [
  { q: 'Is Swipr free?', a: 'Yes. Swipr is free, with no ads, subscriptions or in-app purchases.' },
  {
    q: 'Does swiping left delete the photo right away?',
    a: 'No. It goes into Swipr&rsquo;s trash first. You can restore anything from there, and photos are only deleted when you empty the trash and confirm on your phone.',
  },
  {
    q: 'Are my photos uploaded anywhere?',
    a: 'Never. Swipr works entirely on your device and has no servers to upload to.',
  },
];
