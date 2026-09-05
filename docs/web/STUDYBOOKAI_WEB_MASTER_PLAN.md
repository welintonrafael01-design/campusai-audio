# StudyBook AI Web Master Plan

Status: `W1 IMPLEMENTED LOCALLY - NO DEPLOYMENT`

## URL Contract

- Marketing: `https://studybookai.com`
- Marketing alias: `https://www.studybookai.com` redirects to the canonical apex.
- Flutter application: `https://app.studybookai.com`
- FastAPI backend: `https://api.studybookai.com`

The implementation lives in `web/marketing` and does not replace or embed the
Flutter application. Vercel must use `web/marketing` as the project root.

## W1 Scope

W1 includes Home, Features, Students, Teachers, Pricing, FAQ, Contact,
Security, Privacy, Terms, Account Deletion, 404, robots, sitemap and canonical
metadata. Plans and public URLs have one configuration source. The contact
adapter fails safely while its reviewed endpoint is absent.

## Brand And Booky

The approved colors are `#08152E`, `#00D4FF`, `#8A5CFF` and `#FFFFFF`. The
site uses the existing StudyBook AI brand mark and an anonymized real product
capture. No official Booky character asset exists in the repository, so W1
uses an explicit structural placeholder. Replace it only with the approved
Character Sheet export; do not redraw, recolor or accessorize Booky.

## Remaining Phases

1. Human brand review and official Booky asset handoff.
2. Legal completion of entity, contacts, retention, jurisdiction and age scope.
3. Reviewed contact endpoint with server-side validation and rate limiting.
4. Vercel preview QA, Lighthouse measurements and cross-browser review.
5. Production domain/DNS activation only after all release gates pass.
