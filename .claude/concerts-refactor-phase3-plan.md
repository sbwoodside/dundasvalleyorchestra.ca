# Phase 3 — Bulk concert conversion

## Context

Phase 1 (scaffold) and Phase 2 (3-concert pilot) are committed on `concerts-refactor`. Tooling for bulk conversion is also in place: `.tmp/convert.rb` parses `concerts/index.md` into per-concert `_concerts/*.md` files; `.tmp/check.rb` regenerates expected output and diffs against `_concerts/` plus runs a no-fabrication pass against the source. Both have been validated against the 3 pilots — all CLEAN, all no-fab clean.

The user committed (de69fc9) a manual NBSP cleanup of `concerts/index.md` so source-side normalization is no longer a moving target.

The converter has been extended (this phase) so that **every** chunk produces a file — even the ~6 chunks with irregular structure where the title or date can't be auto-extracted. Those files are written with `needs_review:` in front matter listing the blanks; a human fills them in afterward. The converter does **not** invent values (e.g. no defaulting a missing day-of-month to 1) — anything it can't extract from source verbatim is left blank.

Per the source: 45 H3 concert sections. With the new logic, the script writes all 45 (3 pilots already exist and are skipped); some subset will have `needs_review:` markers.

This phase delivers per-concert files for all ~50 historical concerts so the Phase 4 work (rewriting `concerts/index.md` to render from the collection) can proceed.

## Files to modify

- `_concerts/*.md` — ~42 new files written by the converter (3 pilots already exist and are skipped). A handful of those will carry `needs_review:` markers and require a human to fill in title/date/etc.
- `_data/seasons.yml` — populated at the end of the phase with all distinct seasons.

No source files are modified in this phase. Specifically: `concerts/index.md` is untouched (Phase 4 rewrites it), no layout changes, no `_config.yml` changes.

## Steps

### 1. Bulk auto-conversion

```
ruby .tmp/convert.rb
```

Writes one file per chunk. Files where everything was auto-extracted are tagged `[OK]` in `.tmp/convert.log`; files with blanks for a human are tagged `[REVIEW]` and listed under `=== REVIEW (human fill-ins) ===`. No file should land in `=== MANUAL FIXUP ===` under normal conditions — that section is reserved for unexpected exceptions.

Expected outcome:
- `~37` `[OK]` files (the bulk).
- `~5` `[REVIEW]` files (the irregular chunks).
- `3` skipped (pilots).
- `0` manual.

### 2. Verify the converted batch

```
ruby .tmp/check.rb
```

Immediately after conversion, before any human edits:
- `clean`: 45 (3 pilots + ~37 OK + ~5 review-stubs — all byte-identical to a regenerated stub).
- `diff`: 0.
- `only-actual`: 0.
- `missing`: 0.
- `no-fab clean`: 45.
- `no-fab drift`: 0 (any drift here is a real bug — investigate).

Read `.tmp/check.log` if anything is unexpected.

### 3. Fill in the blanks

For each file in `_concerts/` whose front matter contains `needs_review:`, open it and the corresponding source range in `concerts/index.md`. Fill in the blanks (`title: "TODO"` → real title; missing `date:` → real date; etc.). Remove the `needs_review:` field once done. If the filename starts with `TODO-` (date was unknown), rename to the `YYYY-MM-DD-slug.md` pattern.

Known irregular chunks to expect (current output may differ slightly — trust the `.tmp/convert.log`):

| Source line | H3 in source | Expected blanks |
|---|---|---|
| 954 | `A concert was held Sunday November 9, 2014 at 2pm for Arts Dundas Weekend` | title only (date 2014-11-09 auto-extracted). Suggested title: "Arts Dundas Weekend". **Also: the source body is just an image — see "known limitation" below.** |
| 958 | `Soirée in the Afternoon` | date scanned from body ("June 8, 2014") — verify only. |
| 1033 | `Concert on Sunday, January at 3:00 p.m.` | title + date (filename will be `TODO-…`). Inferred season: 2012-2013, so January 2013. Pick the actual day from external sources or accept as approximate. |
| 1041 | `Concert on Sunday, May at 3:00 p.m.` | parallel to above; May 2013. |
| 1053 | `Concert on Sunday, June 3rd 2012 at 3:00 p.m. at St. Paul's…` | title only (date 2012-06-03 auto-extracted). Suggested title: "The Jubilation of Spring" (per body prose). |
| 1073 | `January 22, 2012 at 3 p.m. at St. Paul's United Church, Dundas` | title only (date 2012-01-22 auto-extracted). Pick a title from body context. |

Body content is already verbatim from source — only front matter needs editing.

### 4. Re-run checker

```
ruby .tmp/check.rb
```

After human edits, `[DIFF]` will appear for every edited file — that's expected noise (the regenerator still produces the original stub). Verify:
- `no-fab drift` = 0 (body content must still appear verbatim in source).
- `only-actual` = 0 (files renamed away from `YYYY-MM-DD-slug.md`-from-stub should still match a source chunk in spirit — but the checker only matches by filename, so a renamed file will appear as `only-actual` + `missing`. That's expected after a rename).
- `missing` may rise to match the rename count; ignore.

The `clean`/`diff` split is no longer informative once humans have edited — focus on no-fab.

### 5. Build verification

```
bundle exec jekyll build
```

Treat warnings as errors per CLAUDE.md guardrail. If a stub file (still containing `title: "TODO"` or missing `date:`) survives to this step, the build should still succeed — Jekyll tolerates string titles and missing date fields — but it's worth catching unfilled stubs here.

```
bundle exec jekyll serve --watch
```

Spot-check at least 5 random concert URLs:
- One next-upcoming, one most-recent past, one mid-season program-only, one with poster + Vimeo, one of the previously-stubbed irregular ones. URLs follow `/concerts/YYYY-MM-DD-slug/`.
- Confirm theme nav + footer intact, side spacing matches the rest of the site, date appears on its own line above time/venue, all media (poster, video, PDF buttons) renders.

The monolithic `/concerts/` page remains live with all concerts including the new individual ones — that's expected (Phase 4 rewrites it).

### 6. Populate `_data/seasons.yml`

Replace the placeholder with all season IDs that appear in the converted concerts:

```yaml
seasons:
  - id: "2025-2026"
    label: "2025-2026 Season"
  - id: "2024-2025"
    label: "2024-2025 Season"
  ... # one per distinct season
```

Order reverse-chronologically. This file feeds Phase 4's season pages.

### 7. Stop and report

Per CLAUDE.md guardrail: do not push past the phase boundary. Report to the user:
- Total concerts converted, broken down by `[OK]` vs `[REVIEW]`.
- Which files needed human fill-ins, and what was filled.
- All checker stats (after human edits — focus on no-fab drift).
- Build status.
- List of URLs spot-checked.

## Known limitation (resolved by hand)

The chunk loop treats the first non-blank line after an H3 as a "metadata" line and excludes it from the body. For chunk 954, that first line is the actual body content (an image) rather than a meta line, so the converter dropped the image from the body. The human patched `_concerts/2014-11-09-concert-for-arts-dundas-weekend.md` by hand; the converter will not be changed.

## Critical files

- `.tmp/convert.rb` — converter (now produces `needs_review:` stubs for ambiguous chunks).
- `.tmp/check.rb` — regeneration + no-fabrication checker (unchanged; `[DIFF]` on edited stubs is expected noise).
- `concerts/index.md` — source (do not modify).
- `_concerts/` — output dir, contains 3 pilots already.

## Out of scope for this phase

- Rewriting `concerts/index.md` to render from the collection (Phase 4).
- Creating per-season stub pages under `concerts/season/` (Phase 4).
- Adding `jekyll-redirect-from` aliases (Phase 5).
- Any layout changes.
- Removing `.tmp/` — keep until Phase 5 merges.
