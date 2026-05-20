# Phase 4 — Index + season pages

## Context

Phase 3 shipped: 45 per-concert files in `_concerts/`, 14 seasons in `_data/seasons.yml`, working `_layouts/concert.html` and `_layouts/season.html`. The monolithic `concerts/index.md` (~1100 lines of hand-maintained concert listings) is now duplicate data — every concert in it also has a per-file representation in `_concerts/`.

Phase 4 replaces that monolith with a Liquid-driven page rendered from the collection, and creates per-season archive pages so visitors can browse older concerts by season.

Per CLAUDE.md, the `/concerts/` page renders:
1. **Next upcoming concert** — rendered in full (chrome + markdown body)
2. **Other upcoming concerts** — same, looped
3. **Past concerts** — cards (poster thumb + title + date + link) from the most-recent past season, followed by links to the other 13 season archives

After Phase 4, only Phase 5 (link audit + redirects + `.tmp/` cleanup) remains.

## Approach

Two small includes eliminate the duplication that would otherwise exist between `_layouts/concert.html` ↔ `concerts/index.md` (full-render chrome) and `_layouts/season.html` ↔ `concerts/index.md` (card markup). This is responding to real duplication that exists *today*, not premature abstraction.

### Files to create

1. **`_includes/concert-full.html`** — full concert render. Takes `include.concert` parameter. Body content is the existing `_layouts/concert.html` lines 5–42 with `page.X` → `include.concert.X` and `{{ content }}` → `{{ include.concert.content }}`. Renders date line, time+venue line, livestream button, video embed, program PDF button, poster image, and the markdown body.

2. **`_includes/concert-card.html`** — concert card (poster thumb + title + date + link). Takes `include.concert`. Body is the existing `_layouts/season.html` lines 9–15 (the `<li>` block) with `c.X` → `include.concert.X`.

3. **`concerts/season/YYYY-YYYY/index.md`** × 14 — folder-as-route per `.claude/docs/architectural_patterns.md`. Each is two lines of front matter:

   ```yaml
   ---
   layout: season
   season: "2025-2026"
   title: "2025-2026 Season"
   ---
   ```

### Files to modify

4. **`_layouts/concert.html`** — replace the inline chrome (lines 5–42) with one call to the new include:

   ```html
   ---
   layout: page
   ---
   {% include concert-full.html concert=page %}
   ```

5. **`_layouts/season.html`** — replace the inline `<li>` block (lines 9–15) inside the existing loop with `{% include concert-card.html concert=c %}`. The surrounding `<ul class="concert-cards">`, `for`, and final `{{ content }}` stay.

6. **`concerts/index.md`** — complete rewrite below the front matter. Preserve front matter as-is (layout: page, title, hero image). Replace everything from line 8 onward with Liquid that:

   - Splits `site.concerts` into upcoming/past by comparing `c.date` to `site.time` (string-compare via `%Y%m%d` is the reliable fallback; try `where_exp` first since both are Time objects).
   - **Drops** the existing top notice / jump-link block — the page is short enough now that jump links aren't useful.
   - Renders Next + Upcoming sections via `{% include concert-full.html concert=c %}` in a loop.
   - Renders Past Concerts section: heading naming the most-recent past season, cards via `{% include concert-card.html concert=c %}` looped over concerts in that season, then a sub-list of links to other season pages (skip the one already shown above).
   - Has a sensible empty-state when there are no upcoming concerts (single-line "No upcoming concerts scheduled. Check back soon." or similar).

   Sketch:

   ```liquid
   {% assign today_str = site.time | date: '%Y%m%d' %}
   {% assign sorted = site.concerts | sort: 'date' %}

   {% comment %} Build upcoming / past arrays {% endcomment %}
   {% assign upcoming_filter = sorted | where_exp: 'c', 'c.date >= site.time' %}
   {% assign past_filter = sorted | where_exp: 'c', 'c.date < site.time' | reverse %}
   {% comment %} If where_exp on dates is unreliable on GH Pages' Liquid version, swap for an explicit for-loop with %Y%m%d string compare. {% endcomment %}

   {% assign next = upcoming_filter | first %}
   {% assign other_upcoming = upcoming_filter | shift %}   {# or offset:1 #}
   {% assign most_recent_past_season = past_filter[0].season %}
   {% assign most_recent_past = past_filter | where: 'season', most_recent_past_season %}

   ## Next Concert
   {% if next %}{% include concert-full.html concert=next %}
   {% else %}_No upcoming concerts scheduled._{% endif %}

   ## Upcoming Concerts
   {% if other_upcoming.size > 0 %}{% for c in other_upcoming %}{% include concert-full.html concert=c %}{% endfor %}
   {% else %}_None at this time._{% endif %}

   ## Past Concerts
   ### {{ most_recent_past_season }} Season
   <ul class="concert-cards">
   {% for c in most_recent_past %}{% include concert-card.html concert=c %}{% endfor %}
   </ul>

   #### Other Seasons
   <ul>
   {% for s in site.data.seasons.seasons %}
     {% unless s.id == most_recent_past_season %}
       <li><a href="/concerts/season/{{ s.id }}/">{{ s.label }}</a></li>
     {% endunless %}
   {% endfor %}
   </ul>
   ```

   No top jump-link notice — the user opted to drop it. Kramdown auto-IDs on headings are sufficient if anything ever needs to link to them.

## Critical files

- `_includes/concert-full.html` (new)
- `_includes/concert-card.html` (new)
- `concerts/season/<YYYY-YYYY>/index.md` × 14 (new)
- `_layouts/concert.html` (simplify to delegate to include)
- `_layouts/season.html` (swap inline card for include)
- `concerts/index.md` (full rewrite below front matter)
- `_data/seasons.yml` (read-only — already populated in Phase 3)

## Verification

1. `bundle exec jekyll build` — no warnings.
2. `bundle exec jekyll serve` and visit:
   - `/concerts/` — confirm Next, Upcoming, Past sections render; cards in Past section have posters; "Other Seasons" sub-list links work.
   - `/concerts/2026-05-31-the-dvo-plays-mahler/` — confirm refactored `_layouts/concert.html` (via include) still renders identically to current.
   - `/concerts/season/2025-2026/` — confirm season page renders with all 2025-2026 concerts as cards (5 concerts: Mahler, Special Online, Celebration of Black History, Christmas Chamber, Space Odyssey).
   - `/concerts/season/2011-2012/` — oldest season, smaller list, exercises the older end of the data.
3. Diff `/concerts/2026-05-31-the-dvo-plays-mahler/` rendered HTML against the pre-refactor version (curl + diff) to confirm the layout extract didn't change output. Acceptable: identical except for incidental whitespace.
4. Verify that the old monolithic `concerts/index.md` content is fully gone from the build (`grep -r 'Songs of the People' _site/concerts/index.html` should miss; the same content is now only in `_site/concerts/2013-01-20-songs-of-the-people/index.html`).
5. Spot-check the date-based upcoming/past split at build time = 2026-05-20 (today): Mahler (2026-05-31) should be in upcoming, everything before should be in past.

## Risks and rollback

- **`where_exp` with Time comparison** — Liquid + Jekyll's GH-Pages-compatible version may handle `c.date >= site.time` correctly, or may stringify and break. If the split misbehaves, switch to an explicit for-loop with `c.date | date: '%Y%m%d' >= today_str` comparison.
- **Folder-as-route consistency** — `concerts/season/2025-2026/index.md` form rather than `concerts/season/2025-2026.md` per architectural docs.
- **Rollback** — `git revert` the Phase 4 commits; the per-concert pages and season data remain intact (they were Phase 3).

## Out of scope

- Phase 5 work: link audit (any `/concerts/#...` anchor references elsewhere in the repo, `jekyll-redirect-from` aliases for old in-page anchors).
- Deleting `.tmp/`, `.claude/conversion-notes.md`, `.claude/concerts-refactor-*` docs — happens at end of Phase 5.
- Visual/CSS adjustments to the existing card grid or concert-body styling.
