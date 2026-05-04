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
- `.github/copilot-instructions.md` — common task examples, editing rules, external service integrations
