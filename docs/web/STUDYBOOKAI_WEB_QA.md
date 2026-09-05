# StudyBook AI Web QA

Status: `LOCAL W2 VISUAL GATE`

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
