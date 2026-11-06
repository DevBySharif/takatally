# Release keystore — Taka Counter

> **Back this up before uploading anything to Play.** Losing the upload key is
> recoverable through Play App Signing, but it is slower and requires a reset
> request. Losing the keystore *and* the password together is worse.

## Where it lives

| Item | Path | Tracked? |
| --- | --- | --- |
| Upload keystore | `android/app/upload-keystore.jks` | **No** — gitignored |
| Signing credentials | `android/key.properties` | **No** — gitignored |
| Signing config | `android/app/build.gradle.kts` | Yes |

`android/key.properties` contains:

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=app/upload-keystore.jks
```

The path is relative to `android/app/`. Do not change the alias or passwords
after the first Play upload unless you also update the file.

## Certificate

```
Alias:      upload
Owner:      CN=Taka Counter, OU=Mobile, O=DevBySharif, L=Dhaka, ST=Dhaka, C=BD
Valid from: 5 November 2026
Valid to:   23 March 2054
Key:        RSA 4096-bit, PKCS12
```

Fingerprints (SHA-1 is the one Google Drive OAuth would need):

```
SHA-1:   35:BF:57:CB:85:1D:85:C1:83:70:DA:C2:79:57:79:BB:1D:E5:EC:BF
SHA-256: 3D:41:5F:F5:38:F9:24:16:5B:FC:01:03:0A:14:05:FB:0B:B7:44:24:AC:87:20:58:6E:99:F9:87:B8:25:60:91
```

Lowercase SHA-1 for OAuth registration:

```
35bf57cb851d85c18370dac2795779bb1de5ecbf
```

## Verify a build

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

`apksigner` lives under the Android SDK `build-tools/<version>/` directory.
The release APK and AAB must both report the certificate above.

## Back up (do this once, now)

1. Create an encrypted archive containing **both** files:
   `upload-keystore.jks` and `key.properties`.
2. Store two copies in separate places — for example an encrypted USB drive and
   a password manager attachment. Do not put them in this repository, a public
   cloud folder, or a chat.
3. Record the store/key passwords in your password manager. The passwords are
   **not** recoverable from the keystore.
4. Write down the alias (`upload`) and the SHA-1/SHA-256 fingerprints.
5. Test a restore on another machine: copy both files into `android/`, then run
   `flutter build apk --release` and verify the certificate. A backup you have
   not restored is not a backup.

## Play App Signing

When you create the app in Play Console, opt in to **Play App Signing**:

- Google generates and holds the **app signing key** used to sign installs.
- Your `upload-keystore.jks` becomes the **upload key**; Play re-signs the AAB.
- If the upload key is lost, Play Console → Setup → App signing → *Request
  upload key reset* issues a new upload certificate. You then replace
  `key.properties` and the keystore.
- The app signing certificate shown on the Play listing is Google's, not this
  upload certificate. That is expected.

Do not enroll in Play App Signing with a keystore you do not control, and do
not let anyone else generate the upload key.

## If the password is lost

- **Upload key password lost, keystore intact:** you cannot use that keystore
  again without the password. Request an upload key reset in Play Console,
  generate a new keystore, and upload the next AAB with it.
- **Keystore file lost:** same reset flow. Existing installs keep updating
  because Google holds the app signing key.
- **Both lost after leaving Play App Signing:** you would need a new package
  name and a new listing. This is why the backup matters.

## Never

- Commit the `.jks` or `key.properties` to Git, a public repo, or a shared
  drive.
- Email the keystore or passwords.
- Reuse this keystore for another app.
- Change `applicationId` after the first Play upload — it is permanent
  (`com.devbysharif.takacounter`).
