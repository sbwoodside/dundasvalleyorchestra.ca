# Dundas Valley Orchestra Website

Static Jekyll website for the Dundas Valley Orchestra, a community orchestra in Hamilton, Ontario. Hosted on GitHub Pages at dundasvalleyorchestra.ca.

## Tech Stack

- **Jekyll** via `github-pages` gem — pins versions to match GitHub Pages production
- **Theme:** remote theme `mmistakes/so-simple-theme@3.2.0` (not vendored; overrides via `_includes/`, `assets/`)
- **Content:** Markdown (kramdown) + Liquid templating
- **Styles:** SCSS — one project file at `assets/css/main.scss` importing theme
- **Ruby 2.7.8** / Bundler — no Node/JS toolchain

## Key Directories

| Path | Purpose |
|------|---------|
| `_config.yml` | Site-wide config: title, URL, theme, analytics, footer links, permalink pattern |
| `index.md` | Homepage content |
| `concerts/index.md` | Master concert listing (~1100 lines); new concerts prepend at top |
| `about/`, `students/`, `members/`, `contact/`, `join-us/`, `support-us/` | Section pages (each has `index.md`) |
| `_data/navigation.yml` | Top-nav link definitions consumed by theme |
| `_includes/footer-custom.html` | Footer override (CRA charitable registration number) |
| `assets/css/main.scss` | Only project stylesheet; sets accent color, imports theme SCSS |
| `images/` | Photos, posters, logos |
| `newsletter/` | Archived "Hi Notes" PDF newsletters |
| `_templates/` | Octopress scaffolding stubs for new pages |
| `_site/` | **Generated output — never edit** |

## Commands

```bash
bundle install                                    # install deps (Ruby 2.7.8)
bundle exec jekyll serve --watch                  # local dev server
JEKYLL_ENV=production bundle exec jekyll build    # production build
```

No automated tests — validate changes by running the site locally.

## Deployment

GitHub Pages auto-builds on push to `master`. `CNAME` at repo root sets the custom domain.

## Additional Documentation

- `.claude/docs/architectural_patterns.md` — theme override pattern, content conventions, kramdown styling, embedded media

## Collaboration preferences

- Do not run destructive cleanup commands (`rm -rf`, `find … -delete`, etc.) — describe what should be removed and let the user run it. Applies even to scratch directories you produced earlier in the same session.

---

## Current focused task: Concerts page refactor

Refactor the monolithic `concerts/index.md` (~50 concerts on one page, no individual URLs) into a Jekyll collection with one file per concert and per-concert URLs. After this task ships, the workflow for adding new concerts changes: instead of prepending to `concerts/index.md`, create a new file under `_concerts/`.

This section can be deleted once the refactor merges to `master`.

### Design decisions (already made — do not relitigate)

**Collection, not posts.** Use a Jekyll collection at `_concerts/` with `permalink: /concerts/:path/`. Filenames are `YYYY-MM-DD-slug.md` (e.g. `_concerts/2026-05-31-dvo-plays-mahler.md` → `/concerts/2026-05-31-dvo-plays-mahler/`). Posts are wrong for this — they impose blog semantics and date-based URLs.

**Lean front matter, content in body.** Only true metadata goes in YAML; the program list, soloist list, and prose description stay in markdown body. Fields (all optional except `title`, `date`, `season`):

```yaml
title: "The DVO plays Mahler!"
date: 2026-05-31
time: "3:00 pm"
season: "2025-2026"
venue: "St. Paul's United Church"   # set as collection default; only override if elsewhere
poster: /images/concerts/2026/poster-2026-05-31.jpg
poster_pdf: /images/concerts/2026/poster-2026-05-31.pdf
program_pdf: /images/concerts/2026/2026-05-31 DVO program.pdf
video_embed: "https://player.vimeo.com/video/..."
livestream_url: https://stpaulsdundas.com/dvo
```

Body contains: description prose, numbered program list (preserve markdown formatting from source), italicized soloist lines, and the existing accessibility/donation boilerplate. Do not invent fields not present in the source.

**Season-based archive pages.** Past concerts paginate by season, not numerically. Each season has a stable URL `/concerts/season/2024-2025/` etc. New concerts never cause page numbers to drift. List all seasons in `_data/seasons.yml`. Season pages render concert cards (poster thumb + title + date + link) reverse-chronologically within the season.

**`/concerts/` index page structure:**
1. Next upcoming concert — rendered in full (its markdown body)
2. Other upcoming concerts — rendered in full (their markdown bodies)
3. Past concerts — cards from the most recent past season, with links to other season archives below

"Next" and "upcoming" are determined by the `date` field vs. today's date at build time. Upcoming concerts are also their own files in `_concerts/` — same schema.

### Layouts and theme integration

This site uses the `so-simple-theme` remote theme. The new `_layouts/concert.html` and `_layouts/season.html` should extend the theme's `default` layout via `layout: default` in their own front matter, then add concert-specific markup inside. Do not duplicate the theme's header/footer/nav scaffolding. See `.claude/docs/architectural_patterns.md` for the existing theme override and kramdown styling conventions.

### Phased execution

Each phase ends with a commit and visual review. Do not skip ahead.

- **Phase 1 — Scaffold.** Add collection to `_config.yml`. Create `_layouts/concert.html` and `_layouts/season.html` (both extending `default`). Create empty `_data/seasons.yml`. Do NOT convert any concerts. Show diff, stop.
- **Phase 2 — Pilot.** Convert exactly 3 concerts from `concerts/index.md`: the next upcoming, one recent with poster + video, one older program-only. Run `bundle exec jekyll build` and `bundle exec jekyll serve`. Stop for human review.
- **Phase 3 — Bulk conversion.** Convert the remaining ~47 concerts. Preserve all program lists, soloist names, embedded videos, image links, and boilerplate exactly. Populate `_data/seasons.yml`. Spot-check 5 random files. Stop for review.
- **Phase 4 — Index + season pages.** Rewrite `concerts/index.md` per the structure above. Create one stub markdown file per season under `concerts/season/` (one-line front matter pointing at `_layouts/season.html`). Stop for review.
- **Phase 5 — Link audit.** Grep entire repo for `/concerts/#` anchor links and other references to the old monolithic page. Update them, or add `jekyll-redirect-from` aliases on the new concert pages. Build, verify locally.

### Guardrails

- **Never bulk-convert before the pilot is reviewed.** A bad schema replicated 50 times is much worse than 3.
- **Preserve content exactly.** Embedded iframes, image paths, link targets, italics — do not "clean up" or modernize the wording. Boilerplate variations across years are intentional historical artifacts.
- **Build between phases.** Run `bundle exec jekyll build` after every phase; treat warnings as errors and report them.
- **Stop and report**, don't push past a phase boundary autonomously.
- **GitHub Pages constraints.** Site builds on plain GH Pages via the `github-pages` gem, which restricts plugins to the GH Pages allowlist. Do not introduce custom Ruby generator plugins — pure Liquid + data files only. `jekyll-redirect-from` is on the allowlist if needed.
- **Don't touch the theme override pattern.** When creating concert/season layouts, follow the conventions documented in `.claude/docs/architectural_patterns.md`.