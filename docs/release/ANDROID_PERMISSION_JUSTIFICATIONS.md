# Android Permission Justifications - StudyBook AI

Evidence source: merged release manifest for version `1.0.0 (1)`.

| Permission / manifest capability | Origin | Required? | Runtime? | User-facing reason / policy impact |
| --- | --- | --- | --- | --- |
| `android.permission.INTERNET` | App | Required | No | Authenticated API, Supabase Auth, document AI and media delivery. Production must use HTTPS. |
| `android.permission.RECORD_AUDIO` | App | Optional feature | Yes | Voice Tutor microphone capture. Request only when the user starts voice input. Voice transcription may leave the device through the OS speech provider and StudyBook backend. |
| `android.permission.ACCESS_NETWORK_STATE` | Media3 transitive dependency | Required by audio stack | No | Audio playback/network state handling. No location implication. |
| `<application-id>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX Core | Internal | No | Signature-protected compatibility permission for non-exported dynamic receivers. Not user data access. |
| `PROCESS_TEXT` query | App | Required compatibility query | N/A | Declares intent visibility only; it is not a runtime permission. |
| `GET_CONTENT` query | `file_picker` | Required | N/A | Uses the system picker for PDFs/files without broad storage access. |

## Confirmed Absent

- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `MANAGE_EXTERNAL_STORAGE`
- `READ_MEDIA_*`
- `POST_NOTIFICATIONS`
- location, contacts, camera and advertising permissions

Storage scope is therefore minimal. The microphone explanation must be visible
in context before the runtime permission request; no background recording was
observed in the current implementation.
