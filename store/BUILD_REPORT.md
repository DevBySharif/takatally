# Build report — Taka Counter 1.0.0

Built locally from a clean tree on **6 November 2026** (Asia/Dhaka). This is
the artifact set to upload to Play Console.

## Upload artifact

| | |
| --- | --- |
| File | `build/app/outputs/bundle/release/app-release.aab` |
| Size | 48,518,696 bytes (46.27 MiB) |
| SHA-256 | `5A6BB4F75184D244BC4B76AA0EE3ECD44B09B91D4BA88BC92532B6347FC9215F` |
| Package | `com.devbysharif.takacounter` |
| versionCode / versionName | `1` / `1.0.0` |
| minSdk / targetSdk / compileSdk | 21 / 36 / 36 |
| Signed by | upload key (`CN=Taka Counter, O=DevBySharif`) |

Native symbols are present under
`BUNDLE-METADATA/com.android.tools.build.debugsymbols/` for arm64-v8a,
armeabi-v7a, and x86_64 (`libflutter.so.sym`).

## Local verification APK

| | |
| --- | --- |
| File | `build/app/outputs/flutter-apk/app-release.apk` |
| Size | 29,936,371 bytes (28.55 MiB) |
| SHA-256 | `5897C97AF8A44A519AD131DF12BBDA40ABF99633BB13565AAF7B0DC774582A13` |
| Signature | verified, v2/v3 |

The APK and AAB contain the same freshly compiled Dart snapshot
(`libapp.so` SHA-256 `f38198a1…1a72fe`), so the local APK reflects exactly what
Play will install.

## Signing certificate

```
Owner:   CN=Taka Counter, OU=Mobile, O=DevBySharif, L=Dhaka, ST=Dhaka, C=BD
SHA-1:   35:BF:57:CB:85:1D:85:C1:83:70:DA:C2:79:57:79:BB:1D:E5:EC:BF
SHA-256: 3D:41:5F:F5:38:F9:24:16:5B:FC:01:03:0A:14:05:FB:0B:B7:44:24:AC:87:20:58:6E:99:F9:87:B8:25:60:91
```

See `KEYSTORE.md` for custody and Play App Signing.

## Permissions

`aapt dump permissions` reports only the app-private, signature-level:

```
com.devbysharif.takacounter.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

This is added by AndroidX for runtime receiver registration. The app declares
**no** internet, location, contacts, camera, microphone, or storage permission.

## 16 KB page size

- `zipalign -c -P 16 -v 4 app-release.apk` → **Verification successful**.
- `libapp.so` and `libflutter.so` LOAD segments use `0x10000` (16 KB) alignment.
- `libdatastore_shared_counter.so` uses at least `0x4000` alignment.

## Quality gate

```
flutter analyze  → No issues found!
flutter test     → 27 tests, all passed
```

Coverage includes money formatting, home/counter/note-counter flows, typed
quantities, breakdown editing, Excel/CSV/JSON import-export, voucher PDFs,
store import edge cases, small-screen + 1.3× text-scale robustness, and the
screenshot harness.

## Store assets

Generated from this build's UI by `tool/make_store_assets.py`:

```
store/icon-512.png                       512 × 512
store/feature-graphic-1024x500.png      1024 × 500
store/screenshots/01-home-light.png     1080 × 1920
store/screenshots/02-counter.png        1080 × 1920
store/screenshots/03-add-entry.png      1080 × 1920
store/screenshots/04-note-counter-filled.png  1080 × 1920
store/screenshots/05-breakdown.png      1080 × 1920
store/screenshots/06-history.png        1080 × 1920
store/screenshots/07-voucher.png        1080 × 1920
store/screenshots/08-settings-data.png  1080 × 1920
```

## Known environment limitation

`flutter build appbundle` exits with status 1 and the message
`Release app bundle failed to strip debug symbols from native libraries`
because Android **cmdline-tools** is not installed (`apkanalyzer` check). The
AAB is complete and valid — the native symbols are in `BUNDLE-METADATA`, and
the bundle was rebuilt with `flutter clean` before this report. Installing
cmdline-tools would make the tool's check pass without changing the artifact.

## Still user-supplied

- Public HTTPS URL for `store/privacy-policy.html`
- A monitored mailbox for `hello@takacounter.app`
- Off-device backup of `android/app/upload-keystore.jks` +
  `android/key.properties`
- Play Console acceptance of the Data safety / content rating answers
