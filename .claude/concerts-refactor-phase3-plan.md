# Phase 3 — Bulk concert conversion

## Context

Phase 1 (scaffold) and Phase 2 (3-concert pilot) are committed on `concerts-refactor`. Tooling for bulk conversion is also in place: `.tmp/convert.rb` parses `concerts/index.md` into per-concert `_concerts/*.md` files; `.tmp/check.rb` regenerates expected output and diffs against `_concerts/` plus runs a no-fabrication pass against the source. Both have been validated against the 3 pilots — all CLEAN, all no-fab clean.

The user committed (de69fc9) a manual NBSP cleanup of `concerts/index.md` so source-side normalization is no longer a moving target.

Per the converter's own report, the source contains 45 H3 concert sections. The script auto-converts 39 of them; 6 are flagged as needing manual creation due to irregular structure (incomplete dates, no date in H3 or metadata, prose-wrapped headings without separable title/date).

This phase delivers per-concert files for all ~50 historical concerts so the Phase 4 work (rewriting `concerts/index.md` to render from the collection) can proceed.

## Files to modify

- `_concerts/*.md` — ~36 new files written by the converter (3 pilots already exist and are skipped). Plus ~6 hand-authored files for the irregular cases.
- `.claude/conversion-notes.md` — append per-concert notes for the 6 hand-authored files and any `[DIFF]` cases the checker flags.

No source files are modified in this phase. Specifically: `concerts/index.md` is untouched (Phase 4 rewrites it), no layout changes, no `_config.yml` changes, no commits to `seasons.yml` (Phase 3 design says populate it during this phase, but that's a tiny one-shot at the end).

## Steps

### 1. Bulk auto-conversion

```
ruby .tmp/convert.rb
```

Writes `_concerts/YYYY-MM-DD-slug.md` for every parseable chunk. Skips files that already exist (the 3 pilots). Expected outcome from the last dry run into `.tmp/expected/`: 36 new files + 6 manual-fixup entries in `.tmp/convert.log`.

### 2. Verify auto-converted batch

```
ruby .tmp/check.rb
```

Expectations:
- `clean`: ~39 (3 pilots + 36 newly converted).
- `diff`: 0 ideally; investigate any nonzero result before continuing — a `[DIFF]` here means a file in `_concerts/` doesn't match what the converter would now produce, which usually points to a converter bug or a hand-edit that drifted.
- `only-actual`: 0 expected.
- `missing`: 6 expected (the manual-fixup cases the converter refused).
- `no-fab clean`: should equal the actual count; any `no-fab drift` means an auto-converted body line doesn't appear verbatim in source (real bug).

Read `.tmp/check.log` and triage anything unexpected. Do not move to step 3 until `diff = 0` and `no-fab drift = 0` for the auto-converted set.

### 3. Hand-author the 6 irregular files

Per the last `.tmp/convert.log`, these chunks have unparseable title/date combinations and need hand authoring. For each, read the source line range, decide an appropriate `title` and `date`, write the file, append a one-paragraph note to `.claude/conversion-notes.md` explaining what was inferred.

| Source line | H3 in source | Approach |
|---|---|---|
| 954 | `A concert was held Sunday November 9, 2014 at 2pm for Arts Dundas Weekend` | title="Arts Dundas Weekend"; date=2014-11-09; season inferred from date |
| 958 | `Soirée in the Afternoon` | title as-is; date from body or surrounding context (look at adjacent concerts and body content) |
| 1033 | `Concert on Sunday, January at 3:00 p.m.` | title="January concert" or similar; date — January 2013 inferred from section "Concerts of the 2012-2013 Season"; pick a Sunday in January 2013 from body context if possible, else flag and skip |
| 1041 | `Concert on Sunday, May at 3:00 p.m.` | parallel to above; May 2013 |
| 1053 | `Concert on Sunday, June 3rd 2012 at 3:00 p.m. at St. Paul's United Church, 29 Park St. W., Dundas` | title="The Jubilation of Spring" (mentioned in body) or generic; date=2012-06-03 |
| 1073 | `January 22, 2012 at 3 p.m. at St. Paul's United Church, Dundas` | title — invent or use first prominent body phrase; date=2012-01-22 |

Each hand-authored file follows the same front-matter + body convention as the auto-converted ones; venue defaults to St. Paul's via `_config.yml` so override only if needed. Copy body content verbatim from source, with the same layout-rendered patterns stripped (livestream button, program PDF button, poster image, Vimeo iframe block).

### 4. Re-run checker

```
ruby .tmp/check.rb
```

Expectations after step 3:
- `clean` = 45 (all chunks have a corresponding clean file).
- `missing` = 0.
- `no-fab drift` = 0.
- `only-actual` = 0.

### 5. Build verification

```
bundle exec jekyll build
```

Treat warnings as errors per CLAUDE.md guardrail. Then:

```
bundle exec jekyll serve --watch
```

Spot-check at least 5 random concert URLs:
- One next-upcoming, one most-recent past, one mid-season program-only, one with poster + Vimeo, one of the 6 hand-authored irregular ones. URLs follow `/concerts/YYYY-MM-DD-slug/`.
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
- Total concerts converted, broken down by auto vs. hand.
- All checker stats.
- Build status.
- List of URLs spot-checked.
- New entries in `.claude/conversion-notes.md`.

## Critical files

- `.tmp/convert.rb` — converter, validated against pilots.
- `.tmp/check.rb` — regeneration + no-fabrication checker.
- `concerts/index.md` — source (do not modify).
- `_concerts/` — output dir, contains 3 pilots already.
- `.claude/conversion-notes.md` — running deviation log.

## Out of scope for this phase

- Rewriting `concerts/index.md` to render from the collection (Phase 4).
- Creating per-season stub pages under `concerts/season/` (Phase 4).
- Adding `jekyll-redirect-from` aliases (Phase 5).
- Any layout changes.
- Removing `.tmp/` and `.claude/conversion-notes.md` — keep both until Phase 5 merges, then clean up.
