# StudyBook AI Web QA

Status: `LOCAL W1 GATE`

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

The numeric Lighthouse targets remain a preview-environment gate. W1 does not
claim scores that were not measured against a deployed Vercel preview.
