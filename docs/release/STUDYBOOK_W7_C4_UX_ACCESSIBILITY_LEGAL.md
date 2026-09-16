# StudyBook AI W7-C4 UX, Accessibility, Contact And Legal

Status: `PRODUCTION VALIDATED - HUMAN LEGAL/CONTACT GATES REMAIN`

Date: `2026-09-16`

Production surfaces reviewed:

- Marketing: `https://studybookai.com`
- Flutter Web: `https://app.studybookai.com`
- API health: `https://api.studybookai.com/health`

Public indexing remained disabled throughout this review. No DNS, database,
provider configuration, deployment or remote branch was changed.

## Production Baseline

| Area | Result | Evidence |
| --- | --- | --- |
| Marketing, Flutter and API | PASS | All three custom-domain origins returned HTTP 200 |
| TLS | PASS | Certificates validate for the custom domains |
| CORS | PASS | The custom Flutter origin receives a valid preflight response |
| Auth and session | PASS | Existing Student A production session remained valid and private routes loaded |
| Logout | PASS | The visible Account action was previously completed and remains reachable at 390 px |
| Password reset | PASS | Fresh PKCE recovery, password update, forced logout, old-password rejection, new-password login and session restore were completed in W7-C2.3 |
| Student/Teacher authorization | PASS | Existing production evidence retains Student 403 and Teacher 200 for the Educator endpoint |
| Public indexing | DISABLED | Root `X-Robots-Tag` is `noindex, nofollow, noarchive`; `robots.txt` disallows `/`; legal metadata is `noindex, nofollow` |

## W7-C4.1 Production Deployment

- Remote QA head: `9a6515a2333cd1eadf65c47dce9d974f9d20964b`.
- Flutter deployment: `dpl_yjRtT1oMLssvp66NVbDEdxLM866U`, READY from the
  remote QA head above.
- Marketing deployment: `dpl_7N5DXfTSn3c1TbDjUeYeguZYUjLi`, READY from the
  remote QA head above.
- Runtime accessibility commit: `8e1800541cb7f2694740f5614cf53c331fc3a19a`.
- The custom domains remained attached. The API origin remained
  `https://api.studybookai.com`; no DNS, provider environment, database or
  indexing setting changed.

## Responsive QA

### Marketing

All 11 required routes were inspected at 390, 768, 1024 and 1440 px:

`/`, `/features`, `/students`, `/teachers`, `/pricing`, `/faq`, `/contact`,
`/security`, `/privacy`, `/terms` and `/account-deletion`.

| Width | Result | Notes |
| --- | --- | --- |
| 390 px | PASS | Header, mobile navigation, hero, Booky, cards, form, legal copy and footer fit without document overflow or clipped primary controls |
| 768 px | PASS | Tablet layout reflows without overlap or horizontal document overflow |
| 1024 px | PASS | Navigation, grids, pricing and long legal content remain usable |
| 1440 px | PASS | Desktop hierarchy, spacing and footer remain intact |

One first-load image observation at Home/390 was a transient lazy-loading race;
an immediate settled-state recheck found zero broken images. The off-screen
Contact input is the intentional `aria-hidden`, `tabIndex=-1` anti-spam
honeypot, not a clipped user control.

### Flutter Web

Authenticated Student views were inspected at 390, 768, 1024 and 1440 px:
Inicio, Biblioteca, Aprendizaje and Cuenta. The isolated unauthenticated Auth
view was also inspected at 390 px.

| Area | Result | Notes |
| --- | --- | --- |
| Auth 390 | PASS VISUAL | Fields and actions fit; keyboard focus is visible |
| Inicio 390 | PASS | Upload and document-selection actions fit; bottom navigation is reachable |
| Biblioteca 390 | PASS | Metrics, search, filters and resource cards remain usable; category chips intentionally scroll within their own row |
| Aprendizaje 390 | PASS | Cards wrap long document names without document-level overflow |
| Cuenta 390 | PASS | Plan is visible and the page scrolls to privacy, deletion and logout controls |
| 768 / 1024 / 1440 | PASS | Student layouts retain navigation and no document-level horizontal overflow |
| Teacher runtime | PASS | Authorized QA Teacher login resolved to Teacher Pro; Teacher Studio and all required areas were sampled at 390, 768, 1024 and 1440 px |

The production Teacher sample covered Cursos, Estudiantes, Asistencia,
Ponderaciones, Calificaciones, Exámenes, Planificación, Rúbricas and Banco de
preguntas. Forms and primary actions were reachable at 390 px; desktop layouts
remained usable. Dense content may scroll inside its intended region without
breaking the page. The existing automated 320 px/text-scale regression remains
supporting evidence.

## Accessibility QA

| Check | Result | Evidence / action |
| --- | --- | --- |
| Marketing landmarks and headings | PASS | Skip link, banner, main, footer, named navigation and logical headings are present |
| Marketing images | PASS | Informative Booky/product images have meaningful alternatives; decorative artwork is hidden |
| Marketing controls | PASS | Native links/buttons and FAQ disclosure buttons are keyboard-operable |
| Marketing focus | PASS | Sampled links and controls show a 3 px cyan focus indicator |
| Mobile menu Escape | PASS LIVE | Escape closes the deployed disclosure and restores focus to the named menu summary |
| Flutter visual focus | PASS | Auth text fields display a clear cyan focus state |
| Flutter Auth names | PASS LIVE | The deployed email, password and primary submit controls expose localized semantic labels |
| Contrast | PASS LIVE | Marketing combinations range from 8.24:1 to 17.38:1 in sampled text; Flutter muted text is 5.70:1 or higher and deployed action colors have tested ratios of 4.59:1 and 4.66:1 with white |
| Reduced motion | PASS | Marketing disables transitions and animations under `prefers-reduced-motion` |
| Screen-reader practical | PASS WITH RETAINED EVIDENCE | Prior physical TalkBack traversal covered core Student, Teacher and Account flows; W7-C4 additionally inspected browser semantics. This is practical QA, not WCAG certification |

No keyboard trap or inaccessible critical control was observed. On Teacher
screens, tab navigation moved between named controls with a visible native
focus outline. The Attendance date dialog exposed named day, Cancelar and
ACEPTAR controls and closed without changing data through Cancelar. This is a
practical accessibility spot check, not a formal WCAG certification.

## Contact Readiness

| Item | Result |
| --- | --- |
| Contact page | SAFE |
| Form presentation | ENABLED UI WITH HONEST DISABLED DELIVERY |
| Provider | `disabled` |
| Disabled-provider response | HTTP 503 with an explicit message that no data was sent |
| Silent discard | ABSENT |
| Support address | NOT APPROVED |
| Privacy address | NOT APPROVED |
| Monitored channel | HUMAN ACTION |

The page states before submission that it will not transmit until a reviewed
endpoint is enabled. The implementation validates origin and payload, includes
an anti-spam honeypot and has per-instance throttling. This is safe for QA but
is not a launch-ready support channel.

Potential aliases documented elsewhere are planning names only. They must not
be published until the human owner confirms that the mailbox exists, is
monitored and has an operating response process.

## Pricing And Product Claims

| Check | Result |
| --- | --- |
| Free | PASS: USD 0 |
| Student Pro | PASS: USD 6.99/month |
| Teacher Pro | PASS: USD 13.99/month |
| Institution | PASS: Contact |
| Free documents | PASS: 3/month |
| Free summaries | PASS: 3/month |
| Free chat | PASS: 10 messages/month |
| Free flashcards | PASS: 1 set/month |
| Free quiz | PASS: 1/month |
| Unlimited claims | NONE |
| Fake metrics/testimonials/logos | NONE |
| Absolute security claim | NONE; the site expressly says no service can guarantee absolute security |
| Unsupported AI accuracy claim | NONE |

The public Free limits match `FREE_MONTHLY_USAGE_LIMITS` and the atomic quota
migration. Legacy Flutter display fields use per-day/per-document names for
paid-plan presentation, but they are not the authority for the public Free
monthly contract.

## Legal Decision Register

This register is a preparation aid, not legal advice or approval.

| Field | Current text/status | Decision required | Recommended safe options for human/legal review | Documents affected |
| --- | --- | --- | --- | --- |
| Legal operator/entity/person | Unresolved | Identify the contracting party and data controller using its exact legal name | Registered entity, registered sole proprietor/person, or postpone public contracting until one is approved | Privacy, Terms, deletion, Contact |
| Business/contact address | Unresolved | Decide whether a public or notice address is required and approve the exact publishable value | Registered business address, approved service address, or counsel-approved alternative | Privacy, Terms |
| Support contact | No monitored channel | Approve and operationally monitor one channel | Verified mailbox, monitored ticket provider, or keep launch blocked | Contact, Terms, deletion |
| Privacy contact | No monitored channel | Approve a channel for privacy/data-right requests | Dedicated monitored mailbox or counsel-approved request system | Privacy, deletion |
| Governing law | Unresolved | Counsel selects governing law consistent with the actual operator | Dominican Republic only if counsel and operator facts support it; otherwise the operator's approved jurisdiction | Terms |
| Jurisdiction/venue | Unresolved | Counsel approves venue and dispute process | Courts, arbitration, consumer venue exceptions, or another counsel-approved mechanism | Terms |
| Effective date | Unresolved | Set only when final text and operational channels are approved | Publication date or another verified launch date | Privacy, Terms |
| Minimum age | Unresolved | Define eligibility based on intended audience and applicable law | Adult-only, guardian/educational consent, or institution-managed access after counsel review | Privacy, Terms, onboarding |
| Minor handling | Unresolved | Define consent, school/guardian roles, deletion and restricted processing | Do not target minors until an approved process exists; or implement the counsel-approved educational model | Privacy, Terms |
| Data retention | No universal schedule | Approve periods by category and deletion trigger | Account data, documents, generated content, operational logs, security records and billing records each need explicit periods | Privacy, deletion |
| Deletion retention exceptions | Technical deletion exists; legal exceptions unresolved | Approve narrowly scoped legal/security/billing exceptions and user wording | Retain only documented categories for documented periods and purposes | Privacy, deletion |
| Subscription billing | Prices exist; contractual wording unresolved | Confirm merchant/provider, charge timing, currency, platform differences and access rules | Stripe Web and Google Play wording based on actual configured channels | Terms, Pricing |
| Automatic renewal | Not approved | State whether each paid channel renews automatically and how notice works | Provider-specific factual wording after console/Stripe verification | Terms, Pricing |
| Cancellation | External subscriptions are not canceled by account deletion | Approve cancellation steps, timing and continued access | Provider-managed cancellation with factual access-through-period wording | Terms, deletion, Pricing |
| Refund policy | Unresolved | Approve eligibility, exclusions and statutory rights | Provider policy plus mandatory consumer-law exceptions as approved by counsel | Terms, Pricing |
| Trial policy | No public paid trial promised | Decide whether no trial remains the policy | Safest current option is no trial claim until a real billing configuration exists | Terms, Pricing |
| Tax wording | Current disclaimer says taxes may vary | Approve merchant/tax responsibility and display rules | Provider-calculated taxes or legally reviewed inclusive/exclusive wording | Terms, Pricing |
| AI-generated content disclaimer | Draft says output may contain errors | Approve review duties, prohibited reliance and domain-specific limitations | Retain truthful assistive-tool wording; add only counsel-approved limitations | Terms, Privacy |
| User-uploaded content rights | User responsibility is stated; license scope unresolved | Define ownership, processing license, permissions and takedown consequences | Narrow service-operation license while user retains ownership, subject to counsel review | Terms, Privacy |
| Copyright/IP complaints | No active process | Approve notice channel, required information and response process | Monitored rights mailbox or verified ticket workflow | Terms, Contact |
| Acceptable use | Topic listed, rules unresolved | Approve prohibited content, misuse, security abuse and enforcement | Narrow rules tied to actual product risks and a documented appeal/contact process | Terms |
| Service availability | No guarantee approved | Approve maintenance, changes, suspension and outage wording | Reasonable availability language without uptime promises not backed by an SLA | Terms |
| Liability language | Unresolved | Counsel approves warranties, exclusions and enforceable limits | Jurisdiction-specific wording; do not copy a generic cap | Terms |
| Third-party processors/providers | Supabase, OpenAI, Stripe, Google Play and device voice services identified | Verify actual roles, regions, terms, transfers and disclosures | Publish only the deployed, contractually verified processor set | Privacy |

Dominican Republic references must remain conditional until the operator and
counsel approve the applicable law, venue, consumer, privacy and minors
position. The existence of drafts does not establish legal compliance.

## P2 Risk Acceptance

| Risk | W7-C4 position | Constraint |
| --- | --- | --- |
| Supabase leaked-password protection unavailable on current plan | P2 ACCEPTABLE ONLY WITH EXPLICIT OWNER ACCEPTANCE | Upgrade and enable before broader exposure when feasible |
| Per-instance API/contact rate limiting | P2 ACCEPTED FOR CONTROLLED SINGLE INSTANCE | Replace with shared enforcement before horizontal scale or meaningful abuse exposure |
| Minor subscription restore delay | CLOSED in current production evidence | Preserve fresh-login/reload regression coverage |
| Teacher entitlement first-render propagation | P2 OBSERVATION | The first Teacher route attempt briefly reflected stale local Free state; backend authority returned active Teacher and the UI self-corrected without privilege escalation |

## Decision

```text
P0: NONE
P1 TECHNICAL: NONE
P1 HUMAN: MONITORED CONTACT CHANNEL AND LEGAL APPROVAL REMAIN OPEN
RESPONSIVE MARKETING: PASS
RESPONSIVE FLUTTER STUDENT: PASS
RESPONSIVE FLUTTER TEACHER: PASS
ACCESSIBILITY PRODUCTION SPOT CHECK: PASS
PUBLIC INDEXING: DISABLED
FINAL DECISION: NO-GO
READY FOR HUMAN LEGAL APPROVAL: YES
READY FOR W7-D: NO
```
