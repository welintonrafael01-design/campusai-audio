# StudyBook AI Web Master Plan

Status: `W2 VISUAL CLOSURE IMPLEMENTED LOCALLY - NO DEPLOYMENT`

## URL Contract

- Marketing: `https://studybookai.com`
- Marketing alias: `https://www.studybookai.com` redirects to the canonical apex.
- Flutter application: `https://app.studybookai.com`
- FastAPI backend: `https://api.studybookai.com`

The implementation lives in `web/marketing` and does not replace or embed the
Flutter application. Vercel must use `web/marketing` as the project root.

## W1 Architecture Preserved

W1 includes Home, Features, Students, Teachers, Pricing, FAQ, Contact,
Security, Privacy, Terms, Account Deletion, 404, robots, sitemap and canonical
metadata. Plans and public URLs have one configuration source. The contact
adapter fails safely while its reviewed endpoint is absent.

## W2 Visual Closure

W2 preserves the App Router structure and introduces the approved premium
visual direction: a clean two-column Home hero, balanced cyan/violet emphasis,
layered navy surfaces, a complete desktop/mobile header, richer feature and
pricing cards, a connected four-step flow, distinct Student and Teacher panels,
factual trust messaging, a stronger final CTA and refined internal audience
pages. Effects use CSS only and are disabled when reduced motion is requested.

## Brand And Booky

The approved colors are `#08152E`, `#00D4FF`, `#8A5CFF` and `#FFFFFF`. The
site uses the existing StudyBook AI brand mark and an anonymized real product
capture. No isolated production-ready Booky PNG/WebP exists in the repository.
W2 therefore uses `BookyStage`, a replaceable branded scene built around
`web/marketing/public/brand-mark.png`; it does not draw or claim to reproduce
Booky's anatomy. No technical placeholder copy is exposed to visitors. Replace
the central mark only with the approved Character Sheet export when delivered;
do not redraw, recolor or accessorize Booky.

The ten-second animation was treated as motion reference only. It is not
embedded, loaded or shipped by the marketing site.

## Remaining Phases

1. Human visual review and official isolated Booky asset handoff.
2. Legal completion of entity, contacts, retention, jurisdiction and age scope.
3. Reviewed contact endpoint with server-side validation and rate limiting.
4. Vercel preview QA, Lighthouse measurements and cross-browser review.
5. Production domain/DNS activation only after all release gates pass.
