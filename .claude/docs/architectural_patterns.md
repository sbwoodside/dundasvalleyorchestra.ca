# Architectural Patterns

## Theme Override Pattern

Jekyll uses a remote theme (`mmistakes/so-simple-theme@3.2.0`). To override theme defaults without vendoring the theme, place files at the same path in:

- `_includes/` — HTML partials (e.g. `_includes/footer-custom.html` overrides theme footer)
- `assets/` — CSS/JS (e.g. `assets/css/main.scss` imports and extends theme styles)
- `_layouts/` — page layouts (none currently overridden)
- `_sass/` — Sass partials (none currently overridden)

Jekyll's load order always prefers local files over gem/remote-theme files at the same path.

## Folder-as-Route Convention

Each URL is a directory containing `index.md` (or `index.html`):

- `/about/` → `about/index.md`
- `/students/young-musician-award/` → `students/young-musician-award/index.md`

This pattern appears in every section. Don't create named `.md` files for top-level pages; use the directory convention.

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

Theme CSS classes are applied via kramdown attribute syntax rather than raw HTML elements. This pattern appears throughout `concerts/index.md`, `students/`, `support-us/`, and `members/`:

- Buttons: `[Label](url){: .btn .btn--accent}` / `.btn--success` / `.btn--info`
- Notice blocks: paragraph text followed immediately by `{: .notice--info}`, `{: .notice--warning}`, or `{: .notice--success}`

## Embedded Media Pattern

External content is embedded via raw HTML `<iframe>` blocks inside Markdown. Used across `index.md` and `concerts/index.md`:

- YouTube: `<iframe src="https://www.youtube.com/embed/VIDEO_ID" ...>`
- Vimeo: `<iframe src="https://player.vimeo.com/video/VIDEO_ID" ...>`
- Google Drive PDFs: `<iframe src="https://drive.google.com/file/d/FILE_ID/preview" ...>`

## Concert Listing Growth Pattern

`concerts/index.md` is a single long file with sections: "Next Concert", "Upcoming Concerts", "Past Concerts". New concerts are prepended to the top of the appropriate section; older concerts accumulate at the bottom. Embedded video iframes appear inline in Markdown when a recording is available.

## Data-Driven Navigation

Top navigation is defined in `_data/navigation.yml` and consumed entirely by the remote theme. To add/remove/reorder nav items, edit that file only — no template changes needed.

## Site-Wide Metadata in `_config.yml`

All global site identity lives in `_config.yml`:

- `title`, `description`, `url` — site identity
- `owner` block — conductor/author info and social links
- `footer_links` — FontAwesome icon links rendered in footer
- `google_analytics` — UA tracking ID
- `google_fonts` — font family declarations

Avoid hardcoding these in content pages; reference via `site.*` Liquid variables when templating requires it.
