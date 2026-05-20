#!/usr/bin/env ruby
# Convert concerts/index.md sections into _concerts/*.md collection files.
# Skips files that already exist (so pilots are preserved).
# Writes a report to .tmp/convert.log.
#
# Targets ~95% accuracy; flags the rest for manual fixup.

require 'date'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
SOURCE_FILE = File.join(ROOT, 'concerts/index.md')
OUTPUT_DIR  = ARGV[0] ? File.expand_path(ARGV[0]) : File.join(ROOT, '_concerts')
REPORT_FILE = File.join(__dir__, 'convert.log')

PILOT_DATES = ENV['PILOTS_ONLY'] ? %w[2026-05-31 2026-02-01 2019-05-26] : nil

FileUtils.mkdir_p(OUTPUT_DIR)

src_lines = File.readlines(SOURCE_FILE).map { |l| l.gsub(" ", ' ') }

# ---- Pass 1: split into per-concert chunks tagged with season ----

chunks = []
current_season = nil
buffer = nil
buffer_start = nil

flush = lambda do
  if buffer && buffer.first&.start_with?('### ')
    chunks << { lines: buffer.dup, season: current_season, start: buffer_start }
  end
  buffer = nil
end

src_lines.each_with_index do |line, idx|
  if (m = line.match(/^## Concerts(?: of the)? (\d{4}-\d{4})/))
    flush.call
    current_season = m[1]
  elsif line.start_with?('### ')
    flush.call
    buffer = [line]
    buffer_start = idx + 1
  elsif line.start_with?('## ')
    flush.call
  else
    buffer << line if buffer
  end
end
flush.call

# Filter out non-concert pseudo-sections like "### 2026-27 Season" or "### TBA"
chunks.reject! do |c|
  h3 = c[:lines].first.sub(/^### /, '').strip
  h3 =~ /^\d{4}-\d{2,4}\s+Season\b/ || h3.casecmp?('TBA')
end

# ---- Helpers ----

MONTHS = %w[January February March April May June July August September October November December]

def slugify(text)
  s = text.dup
  s = s.gsub(/[–—]/, '-')
  s = s.gsub(/['']/, '')
  s = s.gsub(/!/, '')
  s = s.downcase
  s = s.gsub(/[^a-z0-9]+/, '-')
  s = s.gsub(/^-+|-+$/, '')
  s = s.gsub(/-+/, '-')
  s
end

def parse_date(text, hint_year: nil)
  return nil if text.nil? || text.empty?
  t = text.gsub(/[–—]/, '-')
  # "[Weekday[,]] Month D[suffix][,] YYYY"
  if (m = t.match(/(?:[A-Z][a-z]+,?\s+)?([A-Z][a-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})/))
    month, day, year = m[1], m[2].to_i, m[3].to_i
    if MONTHS.include?(month)
      begin
        return Date.new(year, MONTHS.index(month) + 1, day)
      rescue ArgumentError
      end
    end
  end
  # "[Weekday] Month D[suffix]" with hint_year
  if hint_year && (m = t.match(/(?:[A-Z][a-z]+\s+)?([A-Z][a-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?/))
    month, day = m[1], m[2].to_i
    if MONTHS.include?(month)
      begin
        return Date.new(hint_year, MONTHS.index(month) + 1, day)
      rescue ArgumentError
      end
    end
  end
  nil
end

def infer_season(date)
  return nil unless date
  date.month >= 9 ? "#{date.year}-#{date.year + 1}" : "#{date.year - 1}-#{date.year}"
end

def split_title_date(h3_raw)
  # h3_raw is the H3 line content with "### " stripped, no trailing newline
  # Patterns:
  #   "Title – Sunday, May 31, 2026"
  #   "Title – rescheduled – Saturday March 22nd at 7pm"
  #   "Title" (older — date is on next line)
  parts = h3_raw.split(/\s+[–—-]\s+/)
  # If any segment from the end contains a year, treat the join up to it as title
  date_idx = parts.rindex { |p| p =~ /\d{4}/ } # prefer year
  date_idx ||= parts.rindex { |p| p =~ /\b#{MONTHS.join('|')}\b/ }
  if date_idx && date_idx > 0
    title = parts[0...date_idx].join(' – ')
    date_text = parts[date_idx..].join(' – ')
    [title.strip, date_text.strip]
  else
    [h3_raw.strip, nil]
  end
end

def scan_body_for_date(body_lines, hint_year: nil)
  body_lines.each do |l|
    next if l.strip.empty?
    d = parse_date(l, hint_year: hint_year)
    return d if d
  end
  nil
end

def first_meaningful_line(lines)
  # Return first line after H3 that is non-blank
  lines[1..].find { |l| !l.strip.empty? }
end

def parse_metadata_line(line)
  # Examples:
  #   "3pm at [St. Paul's...](url), 29 Park St. W., Dundas..."
  #   "**7pm** at [St. Paul's...](url), addr"
  #   "Sunday May 26, 2019 at 3:00 pm at [St. Paul's...](url), addr"
  #   "March 31, 2026, recorded at St. Paul's United Church"
  result = { time: nil, venue: nil, venue_url: nil, venue_address: nil, date_in_line: nil }
  return result unless line

  # Date in line (for older format with date in metadata)
  if (m = line.match(/((?:[A-Z][a-z]+,?\s+)?[A-Z][a-z]+\s+\d{1,2}(?:st|nd|rd|th)?,?\s+\d{4})/))
    result[:date_in_line] = m[1]
  end

  # Time
  if (m = line.match(/(?:^|\s|\*)(\d{1,2}(?::\d{2})?\s*(?:am|pm|a\.m\.|p\.m\.))/i))
    result[:time] = m[1].strip
  end

  # Venue link [name](url)
  if (m = line.match(/\[([^\]]+)\]\(([^\)]+)\)(?:,\s*(.+?))?(?:\s*$|\s*\{)/))
    result[:venue] = m[1]
    result[:venue_url] = m[2]
    addr = m[3]&.strip
    addr = addr&.sub(/\s*\{:.*$/, '')
    result[:venue_address] = addr
  end

  result
end

# ---- Pattern matchers for body extraction ----

LIVESTREAM_BTN_RE = /^\[View concert livestream(?: \(on the day\))?\]\((https?:\/\/stpaulsdundas\.com\/dvo)\)\{:\s*\.btn\s*\.btn--accent\}\s*$/

PROGRAM_BTN_RE = /^\[(?:Download complete program(?:me)?[^\]]*|Complete Program(?:me)?[^\]]*)\]\(([^)]+\.pdf)\)(?:\{:\s*\.btn[^}]*\})?\s*$/

POSTER_RE = /^\[!\[([^\]]*)\]\(([^)]+\.(?:jpg|jpeg|png))\)\]\(([^)]+\.(?:pdf|jpg|jpeg|png))\)\s*$/

VIMEO_DIV_RE = /^<div style="padding:56\.25%[^"]*">\s*<iframe src="(https?:\/\/player\.vimeo\.com\/video\/[^"]+)"[^>]*><\/iframe><\/div>(?:<script src="https:\/\/player\.vimeo\.com\/api\/player\.js"><\/script>)?\s*$/

VIMEO_PLAIN_RE = /^<iframe[^>]*src="(https?:\/\/player\.vimeo\.com\/video\/[^"]+)"[^>]*><\/iframe>\s*$/

PRECEDING_VIDEO_CAPTIONS = ['Full livestream:', 'View concert livestream recording:', 'View the concert livestream recording:']

def extract_fields_and_body(body_lines)
  fields = {}
  out = []
  removed_captions = []

  body_lines.each do |raw|
    line = raw.chomp

    if (m = line.match(LIVESTREAM_BTN_RE))
      fields[:livestream_url] = m[1]
      next
    end
    if (m = line.match(PROGRAM_BTN_RE))
      fields[:program_pdf] = m[1].gsub('%20', ' ')
      next
    end
    if (m = line.match(POSTER_RE))
      fields[:poster] = m[2]
      pdf = m[3]
      fields[:poster_pdf] = pdf if pdf =~ /\.pdf$/i
      next
    end
    if (m = line.match(VIMEO_DIV_RE)) || (m = line.match(VIMEO_PLAIN_RE))
      fields[:video_embed] = m[1]
      # Pop trailing blank + preceding caption from out, if it matches
      out.pop while out.last && out.last.strip.empty?
      if out.last && PRECEDING_VIDEO_CAPTIONS.include?(out.last.chomp.strip)
        removed_captions << out.pop.chomp
      end
      next
    end
    next if line.strip == '***'

    out << raw
  end

  # Trim leading/trailing blank lines
  out.shift while out.first && out.first.strip.empty?
  out.pop   while out.last  && out.last.strip.empty?

  [fields, out.join, removed_captions]
end

def build_front_matter(title:, date:, time:, season:, venue:, venue_url:, venue_address:, fields:, needs_review: [])
  yaml = +"---\n"
  yaml << "title: #{title.inspect}\n"
  yaml << "date: #{date.iso8601}\n" if date
  yaml << "time: #{time.inspect}\n" if time
  yaml << "season: \"#{season}\"\n" if season
  if venue && venue != "St. Paul's United Church"
    yaml << "venue: #{venue.inspect}\n"
    yaml << "venue_url: #{venue_url.inspect}\n" if venue_url
    yaml << "venue_address: #{venue_address.inspect}\n" if venue_address
  end
  %i[livestream_url video_embed program_pdf poster poster_pdf].each do |k|
    next unless fields[k]
    v = fields[k]
    if v.include?(' ') || v.include?(':') || v.include?('?') || v.include?('&')
      yaml << "#{k}: #{v.inspect}\n"
    else
      yaml << "#{k}: #{v}\n"
    end
  end
  unless needs_review.empty?
    yaml << "needs_review:\n"
    needs_review.each { |n| yaml << "  - #{n.inspect}\n" }
  end
  yaml << "---\n"
  yaml
end

# ---- Pass 2: convert each chunk ----

report = []
report << "=== CONVERT REPORT — #{Time.now} ==="
report << "Source: #{SOURCE_FILE}"
report << "Output: #{OUTPUT_DIR}"
report << "Total chunks parsed: #{chunks.size}"
report << ""

stats = { ok: 0, review: 0, skip: 0, manual: 0 }
manual_entries = []
review_entries = []

chunks.each do |chunk|
  h3_raw = chunk[:lines].first.sub(/^### /, '').rstrip
  src_loc = "concerts/index.md:#{chunk[:start]}"

  begin
    title, date_text_h3 = split_title_date(h3_raw)
    needs_review = []

    # Find the "metadata" line (date/time/venue). Often #1 non-blank after H3.
    # In older format: it's an H4. Strip leading "#### " if present.
    meta_raw = first_meaningful_line(chunk[:lines])
    meta_clean = meta_raw&.sub(/^#+\s*/, '')

    meta = parse_metadata_line(meta_clean)
    date = parse_date(date_text_h3) || parse_date(meta[:date_in_line]) || (meta[:date_in_line] ? parse_date(meta[:date_in_line]) : nil)

    # Hint year from chunk season for date-only without year
    if date.nil? && chunk[:season]
      hint_year = chunk[:season].split('-').last.to_i
      date = parse_date(date_text_h3, hint_year: hint_year) || parse_date(meta_clean, hint_year: hint_year)
    end

    # Fallback: scan the full H3 (no dash split needed — parse_date matches anywhere)
    if date.nil?
      hint = chunk[:season]&.split('-')&.last&.to_i
      date = parse_date(h3_raw, hint_year: hint)
    end

    # Fallback: scan body for a parseable date
    if date.nil?
      hint = chunk[:season]&.split('-')&.last&.to_i
      date = scan_body_for_date(chunk[:lines][1..] || [], hint_year: hint)
      needs_review << "date scanned from body" if date
    end

    # No more fallbacks — if we can't find a real date in the source, leave it
    # blank for the human. Do NOT invent (e.g. day=1 from month-only).
    if date.nil?
      needs_review << "date"
    end

    # If split_title_date couldn't separate a date out, the "title" is the whole H3
    # (likely contains date/venue/prose). Flag it for human cleanup rather than
    # guessing. Detect by checking whether the title still has a year or month in it.
    if title.nil? || title.strip.empty? ||
       title =~ /\d{4}/ || title =~ /\b(?:#{MONTHS.join('|')})\b/
      title = "TODO"
      needs_review << "title"
    end

    season = chunk[:season] || (date && infer_season(date))

    if PILOT_DATES && (date.nil? || !PILOT_DATES.include?(date.iso8601))
      next
    end

    # Body lines = everything after the metadata line
    meta_idx = chunk[:lines].index(meta_raw)
    body_lines = chunk[:lines][(meta_idx + 1)..] || []

    # If meta_clean looks like just a date+venue line, we drop it. But if H3 had no date
    # and metadata had it, that's the right behavior. If meta_raw was an H4, drop.
    # If meta_raw was a non-heading line that includes prose (rare), keep it in body.
    # Simple rule: if meta_raw starts with #### OR matches "{time} at {venue}" OR includes a date-only line, drop it.
    # We're already dropping it (body starts AFTER meta_raw).

    fields, body, removed_captions = extract_fields_and_body(body_lines)

    fname = if date
              "#{date.iso8601}-#{slugify(title)}.md"
            else
              "TODO-#{slugify(h3_raw)}.md"
            end
    out_path = File.join(OUTPUT_DIR, fname)

    if File.exist?(out_path)
      stats[:skip] += 1
      report << "[SKIP] #{fname} (exists)"
      next
    end

    front = build_front_matter(
      title: title,
      date: date,
      time: meta[:time],
      season: season,
      venue: meta[:venue],
      venue_url: meta[:venue_url],
      venue_address: meta[:venue_address],
      fields: fields,
      needs_review: needs_review
    )

    File.write(out_path, front + "\n" + body.gsub(/\n{3,}/, "\n\n").rstrip + "\n")

    tag = needs_review.empty? ? '[OK]' : '[REVIEW]'
    if needs_review.empty?
      stats[:ok] += 1
    else
      stats[:review] += 1
      review_entries << "#{src_loc} → #{fname}: needs_review=#{needs_review.inspect}"
    end
    info = []
    info << "title=#{title.inspect}"
    info << "date=#{date}"
    info << "season=#{season}"
    info << "extracted=[#{fields.keys.join(', ')}]" unless fields.empty?
    info << "needs_review=#{needs_review.inspect}" unless needs_review.empty?
    info << "dropped_caption=#{removed_captions.first.inspect}" if removed_captions.any?
    report << "#{tag} #{fname}  (#{src_loc})"
    report << "     #{info.join('; ')}"
  rescue => e
    manual_entries << "[ERROR] #{src_loc}: #{e.class}: #{e.message}"
    stats[:manual] += 1
  end
end

report << ""
report << "=== STATS ==="
report << "OK (clean, newly written):     #{stats[:ok]}"
report << "REVIEW (stub w/ needs_review): #{stats[:review]}"
report << "Skipped (already exist):       #{stats[:skip]}"
report << "Manual fixup needed:           #{stats[:manual]}"
report << ""
report << "=== REVIEW (human fill-ins) ==="
report.concat(review_entries) unless review_entries.empty?
report << "(none)" if review_entries.empty?
report << ""
report << "=== MANUAL FIXUP ==="
report.concat(manual_entries) unless manual_entries.empty?
report << "(none)" if manual_entries.empty?

File.write(REPORT_FILE, report.join("\n") + "\n")
puts "Wrote #{stats[:ok]} clean + #{stats[:review]} review files, skipped #{stats[:skip]}, #{stats[:manual]} manual."
puts "See #{REPORT_FILE}"
