# Booky Production Asset Authority

## Canonical source

`BOOKY_PRODUCTION_CHARACTER_SHEET_V2.jpeg` is the approved Booky design
authority supplied for StudyBook AI. Its SHA-256 is:

`11d3b22fad30a5526cf4c66a6facf366510292c26b949850bc7a2f79a5612c00`

The source is a complete `1536x1024` character sheet. It is retained here for
internal brand and implementation review. It must not be cropped and presented
as a production-isolated mascot.

## Motion reference

The supplied ten-second Booky MP4 has SHA-256
`eaf20490079689817e8f5443fa4a98d6a6e69687bc6b07dbcf28fb28c4525e45`.
It is not tracked, embedded, or shipped. It may guide only subtle float, idle,
halo, particle, and depth behavior. The character sheet overrides the video
whenever they differ.

## Isolated production asset

The approved isolated frontal asset was supplied as
`8ebed8b4-c114-4cd5-8a15-4d2e22abc72f.png` and is tracked as:

- Master PNG: `web/marketing/public/brand/booky/booky-official-front.png`
- Dimensions: `1254x1254`
- Format: 8-bit RGBA PNG with transparency
- Master SHA-256: `dfec83e401f14e1766f4492f7bd753fcd820d8ad187c4eee71060ceeb130eb7a`
- Optimized WebP: `web/marketing/public/brand/booky/booky-official-front.webp`
- WebP settings: quality `92`, alpha quality `100`, metadata removed
- WebP SHA-256: `c9d3a4d86e068daba09509d999cac742eefadc782c70d7867286ac92d1023df8`
- WebP size: `202790` bytes, versus `942801` bytes for the master PNG

The WebP reduces transfer size by 78.5%. It was visually checked at original
resolution after encoding; no material degradation was found. No Booky pixels
were redrawn, recolored, cropped, accessorized, or otherwise edited. Visual
review against the canonical sheet passed for the flame silhouette, face, eyes,
mouth, translucent galaxy body, emblem, arms, cyan/violet palette, and overall
proportions. The stronger edge glow is accepted as a minor production variation.

The marketing site uses the WebP in the Home hero as informative content and
in the `Conoce a Booky` section as a decorative repeat. The final CTA does not
repeat the asset. CSS provides only ambient light, a soft floor glow, subtle
particles, and reduced-motion-aware floating behavior.

Do not redraw, recolor, accessorize, synthesize, or extract alternate Booky
assets from the character sheet.
