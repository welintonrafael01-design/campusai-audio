# Play App Signing - StudyBook AI

Status: `UPLOAD SIGNING VERIFIED - PLAY APP SIGNING SETUP PENDING`

## Current Evidence

- The upload keystore exists outside the repository and local
  `android/key.properties` remains ignored.
- The signed AAB reports upload certificate SHA-256
  `CD:33:79:B9:43:54:34:31:2C:20:87:DA:53:95:5E:AF:2D:AD:C7:AC:88:AF:02:9B:43:2F:69:58:44:D1:1E:36`.
- The verified AAB SHA-256 is
  `7d127a533944eb3f4f4e3258bb777af37e6c9411462b54eaca0926eda8062d76`.
- A debug-signed release can only be produced when
  `STUDYBOOK_ALLOW_DEBUG_RELEASE_SIGNING=true` is explicitly set. That artifact
  is for local QA only and must never be uploaded to Google Play.

## Remaining Human Procedure

1. Confirm `com.studybookai.app` in the authorized Play Console account.
2. Store the existing keystore and passwords in the approved secret manager
   and backup process.
3. Keep local `mobile/campusai_mobile/android/key.properties` outside Git with
   these keys: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
4. Enroll the app in Play App Signing when creating the first Play release.
   Prefer a Play-managed app signing key and retain the separate upload key.
5. Record the public upload and app-signing certificate fingerprints in the
   controlled release record. Never commit private key material or passwords.

The repository ignores `key.properties`, `*.jks`, and `*.keystore`.

## Local Configuration Template

Create the ignored local file
`mobile/campusai_mobile/android/key.properties`:

```properties
storeFile=/secure/private/studybook/studybook-upload.jks
storePassword=<PROMPTED_SECRET>
keyAlias=studybook-upload
keyPassword=<PROMPTED_SECRET>
```

Verify only public certificate details and the final AAB signature:

```bash
keytool -list -v \
  -keystore /secure/private/studybook/studybook-upload.jks \
  -alias studybook-upload

keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Keep an encrypted backup of the upload keystore and recovery instructions in
separate approved locations. Never commit the keystore, `key.properties`,
passwords or secret-manager exports.

## Release Gate

Upload signing is verified. The current AAB remains a preparation artifact and
must not be uploaded until final public URLs, Play products, server verification
and Play Console setup are complete. Build a new AAB after those values are
approved and record its new hash.

Official reference:
<https://developer.android.com/studio/publish/app-signing>
