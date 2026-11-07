# Release checklist — TakaTally 1.0.0

Work top to bottom. Commands assume the project root
(`D:\Android App\Taka Counter`).

## 1. Before the first upload

- [ ] Back up `android/app/upload-keystore.jks` **and** `android/key.properties`
      to two separate encrypted locations. See `KEYSTORE.md`.
- [ ] Confirm the passwords are in a password manager.
- [ ] Confirm you control `hello@takatally.app` (or change
      `AppInfo.supportEmail` and every store document to a mailbox you read).
- [ ] Host `store/privacy-policy.html` at a public HTTPS URL (GitHub Pages,
      Netlify, or your own site) and keep the URL.
- [ ] Create the Play Console app with package
      `com.devbysharif.takacounter`. The package ID is permanent.
- [ ] Opt in to **Play App Signing**.

## 2. Code gate

```bash
flutter pub get
flutter analyze                 # must print "No issues found!"
flutter test                    # all tests must pass
```

- [ ] `flutter analyze` clean.
- [ ] Full `flutter test` green, including `robustness_test.dart` (small screen
      and 1.3× text scale), `store_import_test.dart`, `entry_editor_test.dart`,
      `note_counter_test.dart`, and `export_import_test.dart`.
- [ ] Manual smoke test on a physical Android device:
  - [ ] add a cash entry by typing amount and note count;
  - [ ] add a note-counter tray and confirm it lands as one entry;
  - [ ] reopen the entry, edit the breakdown, save;
  - [ ] export Excel, open it, check the Breakdown column;
  - [ ] save a backup, import it, check merge and replace;
  - [ ] share a voucher PDF;
  - [ ] toggle dark mode and haptics;
  - [ ] rotate / resize text to 1.3× and check no overflow;
  - [ ] uninstall and reinstall: app starts empty.

## 3. Version

- [ ] `pubspec.yaml` version is correct (`1.0.0+1` for this release).
- [ ] Bump `versionCode` for every upload after the first. `versionName` can be
      user-facing (`1.0.1`, `1.1.0`).
- [ ] Confirm `AppInfo.version` matches `versionName`.

## 4. Screenshots and graphics

```bash
flutter test test/screenshots_test.dart
python tool/make_store_assets.py
```

- [ ] Review all 8 files in `store/screenshots/` at full size.
- [ ] `store/icon-512.png` is 512 × 512, no alpha.
- [ ] `store/feature-graphic-1024x500.png` is 1024 × 500, no alpha.
- [ ] Screenshots show no personal data, no debug banner, no broken layout.

## 5. Build the release artifacts

```bash
flutter clean
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Artifacts:

```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab   <-- upload this
```

> If Dart changes do not appear in a build, check that
> `build/app/intermediates/flutter/release/arm64-v8a/app.so` is newer than your
> `lib/` files. Gradle has occasionally reused a stale snapshot here; run
> `flutter clean && flutter pub get` and rebuild before shipping.

> AAB note: Flutter may print
> `Release app bundle failed to strip debug symbols` and exit 1 when Android
> **cmdline-tools** is missing (`apkanalyzer` check). The AAB is still valid and
> its native symbols are in `BUNDLE-METADATA/.../libflutter.so.sym`. Install
> cmdline-tools if you want the check to pass; do not upload the APK when Play
> expects an AAB.

## 6. Verify the artifacts

```bash
# signing certificate
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk

# package, version, SDK, permissions
aapt dump badging build/app/outputs/flutter-apk/app-release.apk
```

- [ ] Certificate SHA-256 is
      `3D:41:5F:…:25:60:91` (see `KEYSTORE.md`).
- [ ] Package `com.devbysharif.takacounter`, versionCode 1, versionName 1.0.0.
- [ ] `targetSdkVersion` 36, `compileSdkVersion` 36.
- [ ] No dangerous or user-facing permissions. `aapt dump permissions` should
      show only the app-private
      `com.devbysharif.takacounter.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
      that AndroidX adds for runtime receivers — never `INTERNET`, location,
      contacts, camera, microphone, or storage.
- [ ] 16 KB page compatibility:
      `zipalign -c -P 16 4 app-release.apk` passes, and native libraries show
      LOAD alignment `0x10000` (Flutter engine) / at least `0x4000`.
- [ ] Install the signed APK on a device one final time; launch, add an entry,
      export, and share.

Record the final file hashes in the release notes or your own log:

```powershell
Get-FileHash build/app/outputs/bundle/release/app-release.aab -Algorithm SHA256
```

## 7. Play Console — app content

- [ ] **Privacy policy:** paste the hosted HTTPS URL.
- [ ] **Data safety:** follow `DATA_SAFETY.md` — no data collected or shared.
- [ ] **Content rating:** complete the questionnaire using
      `CONTENT_RATING.md`; expected Everyone / PEGI 3.
- [ ] **Target audience:** 18+; do not opt in to Designed for Families.
- [ ] **Ads:** No.
- [ ] **App access:** all functionality available without login.
- [ ] **Financial features:** none of the listed features (counting tool, not a
      financial service).
- [ ] **Government / health / news:** No.
- [ ] **Sensitive permissions:** none declared, so nothing to justify.

## 8. Play Console — store listing

- [ ] App name, short description, full description from `LISTING.md`
      (title: **TakaTally: Note Counter**).
- [ ] Bengali translation added (title, short, full, release notes).
- [ ] Icon, feature graphic, and 8 screenshots uploaded.
- [ ] Category **Finance**; tags optional.
- [ ] Support email `hello@takatally.app`.
- [ ] Phone and tablet screenshots: phone required; tablet optional.
- [ ] Release notes for `1.0.0` pasted.

## 9. Testing tracks

- [ ] Upload the AAB to **Internal testing** first.
- [ ] Add yourself and 2–3 testers; install from the Play link (not sideload).
- [ ] Run the manual smoke test again from the Play-installed build.
- [ ] Check the Play-generated device catalog and pre-launch report.
- [ ] Fix any crash, ANR, or accessibility warning; re-upload with a higher
      versionCode.
- [ ] Promote to **Closed testing** if you want a wider check, then
      **Production**.

## 10. Production rollout

- [ ] Confirm the AAB is the signed one, versionCode 1, target SDK 36.
- [ ] Choose a staged rollout (for example 20% → 50% → 100%) for the first
      release.
- [ ] Submit for review.
- [ ] Watch the Play Console inbox for policy questions; respond with the
      privacy policy and Data safety answers.
- [ ] After approval, install from Play on a clean device and verify the empty
      state, one full count, and one export.

## 11. After release

- [ ] Tag the source state you shipped (`git tag v1.0.0` and push).
- [ ] Keep the AAB, mapping/symbol files, keystore backup, and this checklist
      together.
- [ ] For every future release: bump versionCode, rerun analyze/tests, rebuild,
      re-verify, update “What’s new”, and roll out gradually.
- [ ] If direct Google Drive OAuth is added, update the privacy policy and Data
      safety form first — today’s build only uses the Android share sheet.
