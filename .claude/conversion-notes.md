# Concerts refactor — conversion deviations

Tracks places where converting a concert from `concerts/index.md` into a `_concerts/` collection file did not preserve source body content character-for-character. Most are intentional (e.g. content moved to front matter and rendered by the layout); this file records the rest.

Delete this file once the concerts refactor is fully merged and validated.

## Categories of expected (intentional) drops

These are not noted per-concert; they apply to every conversion:

- H3 title heading (`### Title – Date`) → `title:` + `date:` front matter, rendered by `page` layout as `<h1 class="page-title">` and by `concert` layout as separate date line.
- Time/venue line (`3pm at [St. Paul's...]`) → `time:`, `venue:`, `venue_url:`, `venue_address:` front matter, rendered by layout.
- Livestream button (`[View concert livestream...](url){: .btn .btn--accent}`) → `livestream_url:` front matter.
- Program PDF button (`[Download complete program](url){: .btn .btn--accent}`) → `program_pdf:` front matter.
- Poster image link (`[![alt](poster.jpg)](poster.pdf)`) → `poster:` + `poster_pdf:` front matter.
- Primary embedded video (Vimeo livestream div+iframe) → `video_embed:` front matter.

Date format normalization is also expected: source had varying formats ("Sunday May 26, 2019" vs "Sunday, May 31, 2026"); layout always renders `%A, %B %-d, %Y` (with comma after weekday).

## Per-concert deviations

### 2026-02-01 — Celebration of Black History

- **Dropped:** the inline caption `Full livestream:` that introduced the Vimeo embed in the source body. The layout now renders `video_embed` without a caption above it, so this label has no visual home. Considered minor: the visual context (large embedded video at top of page) makes the label semantically redundant.
- **Preserved in body:** the `Excerpts:` caption + secondary YouTube playlist iframe (this is a separate, secondary embed not covered by `video_embed`).
