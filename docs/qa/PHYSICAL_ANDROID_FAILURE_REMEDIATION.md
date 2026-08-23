# Physical Android Failure Remediation - RC1

Date: 2026-08-22

Device evidence: Samsung SM-N975U, Android 12 (API 31)

Status: `READY_FOR_PHYSICAL_RETEST`

## Remediated Findings

| Finding | Root cause | Resolution | Automated evidence |
| --- | --- | --- | --- |
| Microphone permission P1 | `permission_handler` group 7 is microphone; the main manifest omitted `RECORD_AUDIO`. | Added only `android.permission.RECORD_AUDIO`; guarded concurrent requests and added permanent-denial settings UX. | Manifest and permission-state regression tests pass. |
| Chat overflow P2 | The full document header remained mounted while IME and the active mini player reduced usable height. | Chat uses a compact, fully actionable header while keyboard insets are present. | 411 x 860 viewport with 380 px IME, active mini player and workspace context renders without exception. |
| CIAG extraction P1 | The PDF is an image-only scan with page rotation 270 degrees. OCR received the lateral image and returned reversed text. | OCR now normalizes page rotation and rejects low-confidence extraction before AI generation. | All 8 CIAG pages extract forward; inclusion/accessibility markers are present and reversed marker is absent. |
| Summary mismatch P1 | The summary function received the corrupted OCR text directly. No summary cache or previous-document context exists in this upload path. | Corrected OCR input and constrained summary generation to the supplied text only. | ALPHA/BETA upload test proves each summary receives only its selected document text. |
| Upload disclosure P2 | Upload returned `text_preview` plus an internal registry record containing owner and server/storage paths; Flutter logged the complete map. | Response now exposes only product fields and Flutter emits a redacted structured success line. | Privacy and log-redaction tests pass. |

## Isolation Evidence

- The CIAG registry record has a user owner.
- Its vector collection is `doc_0c88575e5c3bb0fa3c70e00c`.
- All 35 inspected chunks carry that same document ID and page metadata.
- Document chat validates ownership before retrieval.
- Regression coverage proves ALPHA and BETA summaries and RAG contexts do not cross.

Cross-document contamination: `NOT PROVEN`.

RAG document isolation: `PASS` in automated regression.

## Other Device Signals

- Startup frames: 120 and 68 skipped during debug startup; 111 after a debug activity restart. No equivalent release/profile evidence currently demonstrates a product regression. Keep as P2 for physical release retest; no broad refactor was justified.
- File picker: one close warning used the StudyBook PID immediately after the plugin cached the PDF. StudyBook consumes `PlatformFile.bytes` and opens no stream. Keep as P3 plugin warning unless repeated resource growth is measured.
- Lost connection: no StudyBook `FATAL EXCEPTION`, SIGSEGV or OOM exists. The only fatal record belongs to Google Play Services. Classify as unconfirmed debug/transport disconnect.
- Samsung, T-Mobile and Google Play Services noise is excluded from StudyBook findings.

## Required Physical Retest

1. Log in on the Samsung device.
2. Select the same CIAG PDF with the native picker.
3. Upload it and verify that the summary discusses inclusion and accessibility.
4. Open document chat, show the keyboard and confirm there is no overflow.
5. Open Voice Tutor and confirm the real microphone permission prompt appears once.
6. Deny once and verify safe retry; deny permanently and verify the settings action.
7. Grant microphone permission and confirm recognized audio input.
8. Play an AudioBook and verify audible output.
9. Log out and back in.
10. Confirm the app remains stable and capture filtered StudyBook PID logs.

Physical device gate remains `FAIL` until this retest passes. RC2 remains blocked.
