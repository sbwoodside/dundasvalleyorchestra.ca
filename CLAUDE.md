# Dundas Valley Orchestra Website

Static Jekyll website for the Dundas Valley Orchestra, a community orchestra in Hamilton, Ontario. Hosted on GitHub Pages at dundasvalleyorchestra.ca.

## Tech Stack

- **Jekyll** via `github-pages` gem — pins versions to match GitHub Pages production
- **Theme:** remote theme `mmistakes/so-simple-theme@3.2.0` (not vendored; overrides via `_includes/`, `_layouts/`, `assets/`)
- **Content:** Markdown (kramdown) + Liquid templating; concerts are a Jekyll collection
- **Styles:** SCSS — one project file at `assets/css/main.scss` importing theme
- **Ruby 3.3.13** (`.ruby-version`, `Gemfile`) / Bundler — no Node/JS toolchain

## Key Directories

| Path | Purpose |
|------|---------|
| `_config.yml` | Site-wide config: title, URL, theme, analytics, footer links, permalink pattern, `concerts` collection + front-matter defaults (venue) |
| `index.md` | Homepage content (includes hand-updated "last concert" video) |
| `_concerts/` | One file per concert, `YYYY-MM-DD-slug.md` → `/concerts/YYYY-MM-DD-slug/` |
| `concerts/index.md` | Liquid page rendering next/upcoming concerts in full and past concerts as cards, from the collection |
| `concerts/season/YYYY-YYYY.md` | Per-season archive stubs (`layout: season` via `_config.yml` defaults) |
| `_layouts/` | `concert.html` (single concert page), `season.html` (season archive) |
| `_includes/concert-full.html`, `concert-card.html` | Shared concert rendering (full view / card) |
| `_includes/footer-custom.html` | Footer override (Donate button, CRA charitable registration number) |
| `_data/navigation.yml` | Top-nav link definitions consumed by theme |
| `_data/seasons.yml` | Season list (newest first) used for the "Other Seasons" links |
| `about/`, `students/`, `members/`, `contact/`, `join-us/`, `support-us/` | Section pages (each has `index.md`) |
| `assets/css/main.scss` | Only project stylesheet; imports theme SCSS, adds `.concert-cards` styles |
| `images/` | Photos, logos; concert posters/programs under `images/concerts/YYYY/` |
| `newsletter/` | Archived "Hi Notes" PDF newsletters |
| `_templates/` | Octopress scaffolding stubs for new pages |
| `_site/` | **Generated output — never edit** |

## Adding a Concert

Create `_concerts/YYYY-MM-DD-slug.md`. Required front matter: `title`, `date`, `season` (`"YYYY-YYYY"`). Optional: `time`, `venue`/`venue_url`/`venue_address` (defaults to St. Paul's), `poster`, `poster_pdf`, `program_pdf`, `livestream_url`, `video_embed`. Program and description go in the Markdown body. For a new season, also add `concerts/season/YYYY-YYYY.md` and an entry in `_data/seasons.yml`. Full field reference: `.claude/concerts-refactor-plan.md`.

## Commands

```bash
bundle install                                    # install deps (Ruby 3.3.13)
bundle exec jekyll serve --watch                  # local dev server
JEKYLL_ENV=production bundle exec jekyll build    # production build
```

No automated tests — validate changes by running the site locally.

## Deployment

GitHub Pages auto-builds on push to `master`. `CNAME` at repo root sets the custom domain. Build failures show up under the repo's GitHub Actions tab (see `README.md`). Only GitHub Pages–allowlisted plugins work — no custom Ruby plugins.

## Additional Documentation

- `.claude/docs/architectural_patterns.md` — theme override pattern, content conventions, kramdown styling, embedded media
- `.claude/concerts-refactor-plan.md` (+ `-phase3-plan.md`, `-phase4-plan.md`, `conversion-notes.md`) — historical record of the concerts refactor (monolithic page → Jekyll collection with per-concert URLs). Phases 1–4 merged; Phase 5 (link audit / redirects for old `/concerts/#…` anchors) not yet done.

## Collaboration preferences

- Do not run destructive cleanup commands (`rm -rf`, `find … -delete`, etc.) — describe what should be removed and let the user run it. Applies even to scratch directories you produced earlier in the same session.
- Plans live in the repo, not in `~/.claude/plans/`. When the plan-mode harness writes the plan to `~/.claude/plans/<slug>.md`, mirror it on exit to `.claude/<descriptive-name>.md` and commit alongside the implementation. The harness file is then disposable.