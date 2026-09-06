# StudyBook AI Web QA

Status: `W3 TEMPORARY VERCEL PREVIEW VALIDATED`

## W1 Result

| Check | Result | Evidence |
| --- | --- | --- |
| ESLint | PASS | No errors or warnings. |
| Component/unit/route tests | PASS | 4 files, 21 tests. |
| Production build | PASS | Next.js 16.3.4 generated 16 routes. |
| HTTP route smoke | PASS | All expected routes returned 200; unknown route returned 404. |
| Responsive overflow | PASS | 320, 360, 390, 411, 430, 768, 1024, 1280 and 1440 px. |
| Mobile navigation | PASS | Visible, keyboard-addressable and contains all primary links. |
| Browser console | PASS | No warning or error across the route review. |
| Legal draft indexing | PASS | Privacy, Terms and Account Deletion emit `noindex, nofollow`. |
| Flutter URL integration | PASS | 11 focused tests and `flutter analyze` with no issues. |
| Secret scan | PASS | No credential-shaped value in the W1 source or documentation. |

## W2 Result

| Check | Result | Evidence |
| --- | --- | --- |
| Premium Home hero | PASS | Clean two-column composition; application screenshot removed from hero background. |
| Booky structure | BLOCKED FOR FINAL ASSET | Replaceable branded stage uses the existing mark; no unofficial mascot was generated. |
| Header and actions | PASS | Seven public routes plus Login and Start Free; accessible mobile menu. |
| Visual system | PASS | Navy foundation, balanced cyan/violet hierarchy, layered surfaces and restrained glow. |
| Real product preview | PASS | Existing anonymized Voice Tutor capture in a truthful browser frame. |
| Student and Teacher pages | PASS | Distinct cyan/violet hierarchy and truthful product capabilities. |
| Pricing hierarchy | PASS | Student Pro marked `Más popular`; prices remain centralized and unchanged. |
| Factual trust | PASS | No absolute security claim, metrics, testimonials or fabricated affiliations. |
| Responsive overflow | PASS | 320, 360, 390, 411, 430, 768, 1024, 1280 and 1440 px. |
| Reduced motion | PASS | Float, pulse, hover and chevron transitions collapse under the media query. |
| Route and metadata regression | PASS | All public routes retain title, H1, canonical behavior and legal `noindex`. |
| W2 automated tests | PASS | 4 files, 25 tests, including Header/Booky axe structure. |
| Flutter regression | PASS | 11 focused tests and `flutter analyze` with no issues. |

## W2 Screenshot Evidence

- `docs/web/qa/w2/home-desktop-1440.png`
- `docs/web/qa/w2/home-mobile-390.png`
- `docs/web/qa/w2/students-desktop-1440.png`
- `docs/web/qa/w2/teachers-desktop-1440.png`
- `docs/web/qa/w2/pricing-desktop-1440.png`

These are clean viewport captures. Full-page stitching was excluded because the
local browser capture introduced repeated tiles that were not present in the
DOM.

## Automated Gate

Run from `web/marketing`:

```bash
pnpm lint
pnpm test
pnpm build
```

The tests cover the commercial catalog, centralized URLs, FAQ keyboard state,
basic axe checks, contact anti-spam validation, route existence, internal
navigation, sitemap, robots and the custom 404.

## Responsive Matrix

Review Home and one internal route at 320, 360, 390, 411, 430, 768, 1024,
1280 and 1440 pixels. Confirm no horizontal overflow, clipped headings,
inaccessible menu, hidden CTA or layout shift from the product image.

## Accessibility Matrix

- Skip link and semantic landmarks.
- Keyboard navigation and visible focus.
- FAQ state announced with `aria-expanded` and `aria-controls`.
- Form labels, live status and clear no-secret guidance.
- Reduced-motion and forced-colors behavior.
- Heading order, image alternatives and touch target size.

## Human Preview Gate

- Review brand, copy and the real product capture.
- Replace the Booky placeholder only with the official approved asset.
- Complete legal review before removing `noindex`.
- Measure Lighthouse on Vercel preview; local design targets are Performance
  >=90, Accessibility >=95, Best Practices >=95 and SEO >=95.

The numeric Lighthouse targets remain a preview-environment gate. W2 does not
claim scores that were not measured against a deployed Vercel preview.

## W2.1 Booky And Plan Gate

| Check | Result | Evidence |
| --- | --- | --- |
| Character authority | PASS | Canonical V2 sheet stored internally with SHA-256 provenance. |
| Isolated production asset | HUMAN ACTION | Supplied source is a complete sheet, not a transparent isolated Booky. |
| Video usage | PASS | Motion reference only; not embedded or shipped. |
| Free catalog accuracy | PASS | Monthly document, chat, summary, flashcard-set and quiz limits are explicit. |
| Premium claim accuracy | PASS | Free does not advertise AudioBook, Voice Tutor, Question Bank, exams, or unlimited use. |
| W2 composition | PASS | Existing Hero and sections preserved; pricing checked locally at 1280 and 390 px with no horizontal overflow or console errors. |
| W2.1 automated regression | PASS | ESLint clean, 26 marketing tests passed, and Next production build generated all 16 routes. |

## W2.2 Official Booky Integration

| Check | Result | Evidence |
| --- | --- | --- |
| Isolated production asset | PASS | Approved `1254x1254` transparent PNG tracked as the master asset. |
| Visual identity match | PASS | Flame silhouette, face, eyes, mouth, galaxy body, emblem, arms, palette and proportions match V2 authority. |
| Optimized delivery | PASS | Quality-92 WebP with full alpha quality is 202790 bytes, 78.5% smaller than the 942801-byte PNG master. |
| Home hero | PASS | Informative Booky image has meaningful alt text, explicit dimensions, responsive sizes and priority loading. |
| Booky section | PASS | Official artwork replaces the structural mark and is hidden as a decorative repeat from assistive technology. |
| Final CTA | NOT USED | A third Booky placement was intentionally omitted to protect hierarchy and page weight. |
| Reduced motion | PASS | Existing reduced-motion rule collapses Booky float and ambient pulse animations. |
| Responsive matrix | PASS | Production build checked at 320, 360, 390, 411, 430, 768, 1024, 1280 and 1440 px with no overflow, clipped text or escaped Booky image. |
| Production console | PASS | No warnings or errors; Hero image is eager and the decorative repeat remains lazy. |
| W2.2 automated regression | PASS | ESLint clean, 27 marketing tests passed, all 16 routes built, route smoke passed and no broken internal links were found. |
| Flutter regression | PASS | 13 focused configuration, URL-safety and plan-responsive tests passed; `flutter analyze` reports no issues. |

### W2.2 Screenshot Evidence

- `docs/web/qa/w2.2/home-desktop-1440.png`
- `docs/web/qa/w2.2/home-mobile-390.png`
- `docs/web/qa/w2.2/booky-section-desktop.png`
- `docs/web/qa/w2.2/pricing-desktop.png`

The screenshots were captured from the local production build, not the Next.js
development server. The final CTA intentionally does not include a third Booky
instance.

## W3 Vercel Preview

Validation timestamp: `2026-09-05T23:56:24Z`

Preview URL:
`https://temporary-snappy-valley-ek1cq74.vercel.app`

This was an anonymous temporary Vercel Preview of `web/marketing` only. Vercel
advertises a 60-minute lifetime for this temporary deployment, so the URL is QA
evidence rather than a durable project or production endpoint. No custom domain,
DNS record, production deployment or Git push was created.

### W3 Result

| Check | Result | Evidence |
| --- | --- | --- |
| Preview deployment | PASS | Next.js marketing root deployed independently from Flutter Web. |
| Preview indexing protection | PASS | HTML robots metadata, `robots.txt` and `X-Robots-Tag` block indexing only when `VERCEL_ENV=preview`. |
| Public routes | PASS | 11 routes returned 200; the deliberate unknown route returned 404. |
| Broken links and assets | PASS | 27 same-origin targets crawled with query strings preserved; zero failures. |
| Booky delivery | PASS | WebP and PNG master returned 200 with correct MIME; remote hashes match the repository assets. |
| Responsive | PASS | 44 route/viewport combinations plus all nine required Home widths had no horizontal overflow. |
| Cross-browser | PASS | The same production-like journey passed in Chrome/Chromium, Firefox and WebKit: 3 passed. |
| Interaction | PASS | Mobile menu, FAQ accordion, contact status, focus path and reduced-motion behavior validated. |
| Console | PASS | No console errors or uncaught page errors in the cross-browser journey. |
| Contact | HUMAN ACTION | Endpoint is intentionally unset; submission states that no data was sent. |
| Legal | PASS DRAFT | Privacy, Terms and Account Deletion remain explicit drafts and retain `noindex`. |
| App CTA | HUMAN ACTION | CTA targets are centralized under `app.studybookai.com`, which did not resolve during W3. |
| Security headers | PARTIAL | HSTS, frame denial, MIME sniffing protection, referrer and permissions policies pass; CSP remains a follow-up. |
| Secret exposure | PASS | Nine JS bundles and route HTML had no credential-shaped findings; no source maps were exposed. |
| Truthful marketing | PASS | Free limits match product policy and no fake proof, $1 trial, unlimited claim or absolute security claim was found. |

### Lighthouse On Preview

| Page / mode | Performance | Accessibility | Best Practices | SEO | FCP | LCP | CLS | TBT |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Home mobile | 94 | 100 | 100 | 69 | 1.570 s | 2.441 s | 0 | 4 ms |
| Home desktop | 100 | 100 | 100 | 69 | 0.262 s | 0.533 s | 0 | 0 ms |
| Students desktop | 100 | 100 | 100 | 69 | 0.236 s | 0.405 s | 0 | 0 ms |
| Teachers desktop | 100 | 100 | 100 | 69 | 0.253 s | 0.282 s | 0 | 0 ms |
| Pricing desktop | 100 | 100 | 100 | 69 | 0.251 s | 0.319 s | 0 | 0 ms |

The only failed SEO audit was `is-crawlable`. This is expected and required for
the temporary Preview because it is deliberately `noindex`. Titles,
descriptions, canonical URLs, OpenGraph, sitemap and robots rendering were
validated separately. The preview protection must not be removed to inflate a
Lighthouse score.

### W3 Screenshot Evidence

- `docs/web/qa/w3/home-desktop-1440.png`
- `docs/web/qa/w3/home-mobile-390.png`
- `docs/web/qa/w3/students-desktop.png`
- `docs/web/qa/w3/teachers-desktop.png`
- `docs/web/qa/w3/pricing-desktop.png`
- `docs/web/qa/w3/booky-hero.png`

These are stable viewport captures from the deployed Preview. Full-page stitched
captures were excluded because the browser capture surface repeated tiles while
scrolling; DOM counts and screenshots confirmed that repetition was not present
in the deployed page.

### Open W3 Items

1. Create an authenticated, durable Vercel project before production promotion.
2. Deploy and verify `app.studybookai.com` before treating account CTAs as live.
3. Approve and configure a rate-limited contact endpoint.
4. Approve legal entity, jurisdiction, effective date, contacts, retention rules,
   age/minor policy and contractual billing language.
5. Design and test a production CSP without breaking Next.js or analytics that may
   be approved later.
