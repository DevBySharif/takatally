# Google Play — Data safety answers

Use these answers in **Play Console → App content → Data safety**. They match
what the app actually does: everything is local; the app has no internet
permission and no SDKs that transmit data.

## Section 1 — Data collection and security

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not applicable — no data leaves the device |
| Do you provide a way for users to request that their data is deleted? | Not applicable — the developer holds no data. Users can delete entries/counts in the app, clear app storage, or uninstall. |

When the first answer is **No**, Play skips the data-type checklist. Do not add
"Device or other IDs", "Files and docs", or "Financial info" — none are
collected or shared with the developer.

## Section 2 — Data types (only if Play asks)

If the form is shown, mark **none** for every category:

- Personal info — none
- Financial info — none
- Health and fitness — none
- Messages — none
- Photos and videos — none
- Audio — none
- Files and docs — none
- Calendar — none
- Contacts — none
- App activity — none
- Web browsing — none
- App info and performance — none
- Device or other IDs — none
- Location — none

## Section 3 — Other declarations

| Item | Answer | Why |
| --- | --- | --- |
| Ads | **No ads** | No ad SDK or ad network. |
| In-app purchases | **No** | The app is free with no paid content. |
| Account creation | **No** | No sign-in, profile, or account. |
| App access | **All functionality available without restrictions** | Nothing is behind a login. |
| Financial features | **None of the listed financial features** | The app is a counting/ledger tool. It does not provide loans, payments, money transfer, banking, crypto, insurance, or investment services. |
| Government app | **No** | Not created by or for a government. |
| Health app | **No** | Not a health app. |
| News app | **No** | Not a news app. |
| Target audience | **18+** | Financial utility for adults; not designed for children. |
| Families policy | **Not participating** | Do not opt in to Designed for Families. |

## Why "no data collected" is accurate

- Storage is `SharedPreferences` in the app's private sandbox.
- `android.permission.INTERNET` is **not** declared; the merged manifest has
  no network, location, contacts, camera, microphone, or storage permission.
- `allowBackup="false"` keeps app data out of Android cloud backup.
- No analytics, crash reporting, advertising, or attribution SDK is included.
- Exports happen only on an explicit user action and go to the app **the user
  chooses** through the Android share sheet / system file picker. The developer
  never receives them, so they are not "shared" with the developer under Play's
  definition.
- The app reads only the file the user picks when importing.

## Evidence to keep

- `android/app/src/main/AndroidManifest.xml` — no permissions.
- `flutter pub get` dependency list — no analytics/ads packages.
- `build/app/outputs/flutter-apk/app-release.apk` — verify with
  `aapt dump permissions` or Play Console's APK analysis: no permissions.
- This repo's privacy policy (`PRIVACY_POLICY.md` / `privacy-policy.html`).

## If Google Drive sync is added later

Direct Google Drive OAuth (not the share-sheet flow) would change these
answers: it would require the internet permission, a Google account
connection, and possibly "Files and docs" access. Update the Data safety form
and privacy policy before shipping that version. Today's build does not do it.
