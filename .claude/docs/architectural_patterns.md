# Architectural Patterns

## Theme Override Pattern

Jekyll uses a remote theme (`mmistakes/so-simple-theme@3.2.0`). To override theme defaults without vendoring the theme, place files at the same path in:

- `_includes/` — HTML partials (e.g. `_includes/footer-custom.html` overrides theme footer)
- `assets/` — CSS/JS (e.g. `assets/css/main.scss` imports and extends theme styles)
- `_layouts/` — page layouts (project adds `concert.html` and `season.html`; theme layouts not overridden)
- `_sass/` — Sass partials (none currently overridden)

Jekyll's load order always prefers local files over gem/remote-theme files at the same path.

### SCSS override entry point

`assets/css/main.scss` is the project's single stylesheet. It mirrors the theme's own entry point and overrides it. It must:

- Begin with YAML front matter (just `--- / sitemap: false / ---` is enough). Jekyll only Sass-compiles files that have front matter.
- `@import "so-simple";` to pull in the theme's `_sass/` partials. Without this, the page is unstyled.
- Add custom rules below the import. They cascade over theme defaults because they appear later.

The theme's stock `main.scss` is in the gem at `jekyll-theme-so-simple-3.2.0/assets/css/main.scss` — useful as a reference for what to mirror, but the local file takes precedence at build time.

## Page File Layout

Top-level sections use folder-as-route (a directory containing `index.md` or `index.html`):

- `/about/` → `about/index.md`
- `/students/young-musician-award/` → `students/young-musician-award/index.md`

Named `.md` files at the same level are also acceptable when one-file-per-stub is more ergonomic than one-subdir-per-stub (e.g. per-season archive pages under `concerts/season/`). Either form is fine; pick whichever keeps the surrounding tree clean.

## Front Matter Conventions

All content pages use this consistent structure (`_config.yml` permalink: `/:categories/:title/`):

```yaml
---
layout: page
title: Page Title
image:
  path: /images/photos/filename.jpg
---
```

The `image.path` key sets the hero image. Omit it on pages without a header image.

## Kramdown Attribute Lists for Styling

Theme CSS classes are applied via kramdown attribute syntax rather than raw HTML elements. This pattern appears throughout `_concerts/*.md`, `students/`, `support-us/`, and `members/`:

- Buttons: `[Label](url){: .btn .btn--accent}` / `.btn--success` / `.btn--info`
- Notice blocks: paragraph text followed immediately by `{: .notice--info}`, `{: .notice--warning}`, or `{: .notice--success}`

## Embedded Media Pattern

External content is embedded via raw HTML `<iframe>` blocks inside Markdown. Used in `index.md` and some `_concerts/*.md` bodies:

- YouTube: `<iframe src="https://www.youtube.com/embed/VIDEO_ID" ...>`
- Vimeo: `<iframe src="https://player.vimeo.com/video/VIDEO_ID" ...>`
- Google Drive PDFs: `<iframe src="https://drive.google.com/file/d/FILE_ID/preview" ...>`

## Concert Listing Growth Pattern

Each concert is its own file in the `_concerts/` collection. `concerts/index.md` contains no concert content — it is pure Liquid that sorts the collection by `date` and splits it against `site.time` into "Next Concert", "Upcoming Concerts" (rendered in full via `_includes/concert-full.html`) and "Past Concerts" (cards via `_includes/concert-card.html` for the most recent past season, plus links to `/concerts/season/<id>/` archives from `_data/seasons.yml`). Media and links are front-matter fields (`video_embed`, `livestream_url`, `poster`, `program_pdf`, …) rendered by the include, not inline Markdown.

## Data-Driven Navigation

Top navigation is defined in `_data/navigation.yml` and consumed entirely by the remote theme. To add/remove/reorder nav items, edit that file only — no template changes needed.

## Site-Wide Metadata in `_config.yml`

All global site identity lives in `_config.yml`:

- `title`, `description`, `url` — site identity
- `author` block — site owner name, picture, email
- `footer_links` — FontAwesome icon links rendered in footer
- `google_analytics` — UA tracking ID
- `google_fonts` — font family declarations

Avoid hardcoding these in content pages; reference via `site.*` Liquid variables when templating requires it.
