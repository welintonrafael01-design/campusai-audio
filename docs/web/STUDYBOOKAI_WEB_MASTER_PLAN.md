# StudyBook AI Web Master Plan

Status: `W2.2 BOOKY VISUAL CLOSURE IMPLEMENTED LOCALLY - NO DEPLOYMENT`

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
site uses the existing StudyBook AI brand mark, an anonymized real product
capture, and the approved isolated frontal Booky. `BookyStage` now renders the
optimized WebP at
`web/marketing/public/brand/booky/booky-official-front.webp`, while the supplied
transparent PNG remains tracked beside it as the production master. Explicit
image dimensions and responsive `sizes` prevent layout shift and avoid serving
desktop-sized output unnecessarily on small screens.

The canonical full character sheet is stored for internal review at
`docs/brand/booky/BOOKY_PRODUCTION_CHARACTER_SHEET_V2.jpeg`, with provenance
and hashes in the adjacent README. It remains the identity authority and is not
served by the marketing app. Visual comparison passed; no anatomy, face,
palette, texture, emblem, or proportions were modified.

The ten-second animation was treated as motion reference only. It is not
embedded, loaded or shipped by the marketing site.

## W2.1 Commercial Accuracy

The Free pricing card now states the enforced monthly discovery quotas and
does not imply access to AudioBook, Voice Tutor, Question Bank, Exam Generator,
or unlimited AI. Student Pro and Teacher Pro retain their approved USD 6.99
and USD 13.99 monthly positions.

## Remaining Phases

1. Human review of the W2.2 local screenshots with the official Booky asset.
2. Legal completion of entity, contacts, retention, jurisdiction and age scope.
3. Reviewed contact endpoint with server-side validation and rate limiting.
4. Vercel preview QA, Lighthouse measurements and cross-browser review.
5. Production domain/DNS activation only after all release gates pass.
