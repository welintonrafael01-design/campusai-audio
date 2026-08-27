# Play App Signing - StudyBook AI

Status: `BLOCKED - HUMAN ACTION REQUIRED`

## Current Evidence

- The Android release variant previously used the local Android debug key.
- The Gradle configuration now accepts an ignored `android/key.properties`
  file for release signing.
- A debug-signed release can only be produced when
  `STUDYBOOK_ALLOW_DEBUG_RELEASE_SIGNING=true` is explicitly set. That artifact
  is for local QA only and must never be uploaded to Google Play.
- No production keystore or upload key was created by Plan Master 7E.

## Required Human Procedure

1. Confirm the final application ID before generating or registering keys.
2. Create an upload key in an approved secure workstation or key-management
   process. Do not create it in the repository.
3. Store the keystore and passwords in the approved secret manager and backup
   process.
4. Create local `mobile/campusai_mobile/android/key.properties` with these
   keys: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
5. Build the AAB with the canonical release command and verify that its signer
   is not `CN=Android Debug`.
6. Enroll the app in Play App Signing when creating the first Play release.
   Prefer a Play-managed app signing key and retain the separate upload key.
7. Record the public upload and app-signing certificate fingerprints in the
   controlled release record. Never commit private key material or passwords.

The repository ignores `key.properties`, `*.jks`, and `*.keystore`.

## Release Gate

Release signing is `READY` only when a non-debug upload key signs the final AAB
and the authorized owner has confirmed the Play App Signing setup. The current
debug-signed QA artifact is `NOT UPLOADABLE`.

Official reference:
<https://developer.android.com/studio/publish/app-signing>
