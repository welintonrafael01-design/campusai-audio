# Play Console Readiness

Status: `SIGNED ARTIFACT VERIFIED - CONSOLE AND PUBLIC INFRASTRUCTURE PENDING`

No upload, Play Console mutation, tag or deployment is performed by this
document.

## Verified Android Identity

| Item | Verified value | Status |
| --- | --- | --- |
| Package | `com.studybookai.app` | Ready |
| Version name | `1.0.0` | Ready |
| Version code | `1` | Ready |
| Target SDK | `36` | Ready |
| Upload certificate SHA-256 | `CD:33:79:B9:43:54:34:31:2C:20:87:DA:53:95:5E:AF:2D:AD:C7:AC:88:AF:02:9B:43:2F:69:58:44:D1:1E:36` | Verified from signed AAB |
| Signed AAB SHA-256 | `7d127a533944eb3f4f4e3258bb777af37e6c9411462b54eaca0926eda8062d76` | Verified locally |

The AAB proves productive upload signing. It is not approved for upload because
the final production domain, public URLs, Play products and live server
verification are still pending.

## Play Console Human Checklist

- Create/register `com.studybookai.app` in the authorized developer account.
- Enroll in Play App Signing and register the verified upload certificate.
- Create the Student Pro and Teacher Pro subscription products; record their
  actual IDs only after Play Console creates them.
- Configure license testers and test tracks.
- Configure app access with non-personal reviewer credentials.
- Complete content rating, target audience, ads declaration and category.
- Publish approved website, support, privacy-policy and account-deletion URLs.
- Reconcile the Data Safety form with deployed processors and retention.
- Upload store listing copy, icon, feature graphic and screenshots after final
  product review.

## Billing Deployment Gate

Flutter placeholders:

- `STUDENT_PRO_PLAY_PRODUCT_ID`
- `TEACHER_PRO_PLAY_PRODUCT_ID`

Backend mappings:

- `GOOGLE_PLAY_STUDENT_PRODUCT_ID`
- `GOOGLE_PLAY_TEACHER_PRODUCT_ID`

The backend integration point is `POST /billing/google-play/verify-purchase`.
Its current default verifier returns `503` and grants no entitlement. A
backend-only Google Play Developer API implementation and credentials are
required before purchase testing. Never place service-account credentials in
Flutter or release JSON.

## Final Artifact Gate

After domain and Play configuration are complete:

1. Build a new signed AAB from the reviewed commit.
2. Run `tools/qa/check_android_release.sh` with final public configuration and
   the new AAB.
3. Verify package, version, target SDK, upload signer and SHA-256.
4. Run the final security and targeted billing tests.
5. Record the new artifact hash; the hash above must not be assumed final.
