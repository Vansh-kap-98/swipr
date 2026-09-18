# Swipr launch checklist

Status on 2026-09-18: the app is code-complete for v1 (analyzer clean, 24 tests passing, release APK builds) but **has never run on a real phone**. The website is built and checked, but not deployed.

Items marked **blocker** must be done before anyone else installs the app.

---

## 1. Test on real devices — blocker

Nothing below matters until the app has been used on real hardware.

- [ ] Run on a real Android phone: `flutter run --release`
- [ ] Run on a real iPhone (needs a Mac — see section 4)
- [ ] Swipe through a large album (2,000+ photos): check scrolling stays smooth, memory is stable, and loading a scope isn't slow
- [ ] Confirm the delete flow end to end: mark photos → Empty Trash → the system dialog appears once → photos are gone → "Freed X MB" is correct
- [ ] Cancel the system delete dialog: nothing should be deleted and the trash should stay intact
- [ ] Kill the app during the delete dialog, reopen it: the trash should reconcile without duplicates
- [ ] Undo: several steps back, and undo right after an Empty Trash
- [ ] Deny photo permission, then grant it from Settings
- [ ] "Limited"/"Selected photos" access on iPhone and Android 14+, including Select more
- [ ] Android version spread: 8/9 (write permission path), 10 (per-photo delete prompts), 11–12, 13, 14+
- [ ] Empty album, album with one photo, and a library where a photo was deleted in another app
- [ ] Screen reader pass: TalkBack and VoiceOver can reach and use the ✕/✓/undo buttons
- [ ] Check performance in profile mode (`flutter run --profile`) while swiping fast

## 2. App identity and assets — blocker

- [ ] **Launcher icons are still Flutter's default** on both platforms. Design a real icon and generate all sizes (`flutter_launcher_icons` does both, including the Android adaptive icon)
- [ ] Decide the final app ID: currently `com.swipr.swipr` on both platforms. **It can never change after publishing**
- [ ] Check the name "Swipr" isn't taken on either store and doesn't collide with an existing trademark
- [ ] Confirm the display name shown under the icon ("Swipr") is what you want
- [ ] Decide the iOS launch screen look (currently a plain dark screen)

## 3. Android release build — blocker

- [ ] Create an upload keystore and `android/key.properties`, and switch `signingConfig` in `android/app/build.gradle.kts` off `debug` ([guide](https://docs.flutter.dev/deployment/android#signing-the-app))
- [ ] Back up the keystore and its passwords somewhere safe — losing it means you can never update the app
- [ ] Add `key.properties` and `*.jks` to `.gitignore` (the project isn't a git repo yet — see section 9)
- [ ] Build an App Bundle for Play: `flutter build appbundle --release`
- [ ] Build split APKs for the website: `flutter build apk --split-per-abi --release` (~20 MB each instead of 46.7 MB)
- [ ] Install the signed build on a clean phone and check it opens, gets permission and deletes photos
- [ ] Confirm the release build's permission list is still only the photo ones

## 4. iOS release build — blocker for the App Store

- [ ] You need a Mac (or a cloud Mac service like Codemagic or Xcode Cloud) — iOS apps can't be built on Windows
- [ ] Apple Developer Program membership ($99/year)
- [ ] Register the bundle ID, create the signing certificate and provisioning profile
- [ ] `flutter build ipa --release`, then upload with Transporter or Xcode
- [ ] Test through TestFlight on a real iPhone before submitting

## 5. Store accounts and listings

- [ ] Google Play developer account ($25 one-time). Personal accounts opened recently need 12 testers for 14 days before production — check the current rule
- [ ] Apple Developer Program (above)
- [ ] Screenshots: Play needs at least 2 phone screenshots; Apple needs 6.7" and 6.5" sets. Take them from a real device after section 1
- [ ] Play feature graphic (1024×500)
- [ ] Short description (80 chars) and full description (4,000 chars) — the website's home page copy is a good starting point
- [ ] App Store subtitle, keywords (100 chars), promotional text
- [ ] Category: Photo & Video (Apple) / Photography (Play)
- [ ] Support URL and contact email — use the site's FAQ page and a real address, not a placeholder
- [ ] Privacy policy URL — point it at the deployed `/privacy/` page (required by both stores)
- [ ] Content rating questionnaire (Play) and age rating (Apple)
- [ ] **Play Data safety form:** no data collected, no data shared, no encryption in transit needed (nothing is sent)
- [ ] **Apple App Privacy ("nutrition label"):** Data Not Collected
- [ ] Ads declaration: no ads
- [ ] EU trader status declaration (both stores now require it for EU distribution)
- [ ] Decide launch countries and whether to start with an internal/closed test track

## 6. Legal and policy

- [ ] Review the privacy policy once contact details and the domain are final; it must match what the app does
- [ ] Set the app's privacy policy effective date
- [ ] Decide if you want terms of service (not required for a free offline utility)
- [ ] Both stores treat photo access as sensitive: the listing should explain plainly why the app needs it

## 7. Website

- [ ] Buy the domain and set `url` in [web/site.config.ts](web/site.config.ts) (currently the placeholder `swipr.app`)
- [ ] Set `contactEmail` (currently `hello@swipr.app`)
- [ ] Deploy `web/out/` to a static host (Netlify, Cloudflare Pages, GitHub Pages). `out/_headers` works as-is on Netlify and Cloudflare
- [ ] Point the 404 handler at `404.html`
- [ ] Verify HTTPS and that the security headers are actually applied
- [ ] Publish only a **properly signed** APK, or remove the direct download and link to Play instead
- [ ] Add the store links to `site.config.ts` once the listings are live, then rebuild
- [ ] Submit `/sitemap.xml` in Google Search Console and Bing Webmaster Tools
- [ ] Test how the link previews look when shared (the Open Graph image)

## 8. Decisions worth making before launch

- [ ] **No crash reporting.** Nothing is collected, which is great for privacy but means you'll never hear about crashes except through email. Accept, or add an opt-in reporter and update the privacy policy and store forms
- [ ] **iCloud downloads on iPhone:** the photo package always allows iOS to fetch full-quality copies from the user's iCloud. It's the OS talking to the user's own account, but the privacy page should keep saying so
- [ ] **English only** — no translations in v1
- [ ] **Support channel:** who answers the contact email
- [ ] Decide what version 1.1 is (duplicate detection, videos, backup checks) so reviews have an answer

## 9. Project housekeeping

- [ ] The project isn't a git repository. Run `git init` and commit before publishing anything
- [ ] Decide public or private repository; if public, keep the keystore and `key.properties` out of it
- [ ] Run `flutter analyze` and `flutter test` one more time before building the release
- [ ] Tag the release and keep the exact APK/AAB you publish

## 10. After launch

- [ ] Watch Play Console's pre-launch report and vitals (ANRs, crashes) — these arrive even with no in-app reporting
- [ ] Read the first reviews for permission or deletion confusion
- [ ] Keep `version:` in `pubspec.yaml` moving; Play rejects duplicate version codes
