# Android SDK Inventory - StudyBook AI

This inventory prioritizes libraries relevant to Play policy, data collection,
native code, media and permissions. Play SDK Index status requires manual Play
Console review.

| SDK / package | Version observed | Function | Data/policy relevance |
| --- | --- | --- | --- |
| Flutter | 3.41.9 / engine 42d3d75a56 | UI/runtime | Native runtime and ABI/page-size compatibility |
| `supabase_flutter` | 2.12.4 | Auth/session and app links | Account identity and session persistence |
| `http` | 1.6.0 | Backend networking | Transports user content and metadata |
| `file_picker` | 8.3.7 | System document selection | Uses picker; no broad storage permission |
| `just_audio` | 0.9.44 | AudioBook/TTS playback | Media3 native Android dependencies, network state |
| `speech_to_text` | 7.4.0 | Voice Tutor transcription | Microphone and platform speech processing |
| `permission_handler` | 12.0.3 | Runtime permission flow | Microphone permission |
| `shared_preferences` | 2.5.5 | User-scoped local preferences/cache | Device-resident account-linked data |
| `url_launcher` | 6.3.2 | External URLs | Billing URL currently raises Play Payments review |

Relevant Android transitive components include AndroidX Core, Lifecycle,
Profile Installer, Window, DataStore and Media3. The generated SDK dependency
metadata is present in the release artifact.

## External Processors Without Native Android SDK

- OpenAI: backend AI, embeddings and TTS.
- Stripe: backend Checkout/customer portal/webhooks.
- Supabase backend database and Storage via FastAPI service role.

## Confirmed Absent

No Firebase, Crashlytics, Sentry, Google Mobile Ads/AdMob, Meta Ads, Adjust or
AppsFlyer dependency was found. This does not replace a Play SDK Index review of
the final uploaded AAB.
