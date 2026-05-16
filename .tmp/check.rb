#!/usr/bin/env ruby
# Verify _concerts/*.md against re-generated output from convert.rb.
# Approach: regenerate fresh output into .tmp/expected/, then diff each file.
# Honors PILOTS_ONLY=1 to limit to the three pilot dates.
#
# Writes report to .tmp/check.log.

require 'fileutils'
require 'set'

ROOT         = File.expand_path('..', __dir__)
ACTUAL_DIR   = File.join(ROOT, '_concerts')
EXPECTED_DIR = File.join(__dir__, 'expected')
REPORT_FILE  = File.join(__dir__, 'check.log')
CONVERT      = File.join(__dir__, 'convert.rb')
SOURCE_FILE  = File.join(ROOT, 'concerts/index.md')

def normalize(s)
  s.gsub(" ", ' ').rstrip
end

def extract_body(path)
  text = File.read(path)
  m = text.match(/\A---\n.*?\n---\n(.*)\z/m)
  m ? m[1] : text
end

# Regenerate expected output fresh
FileUtils.rm_rf(EXPECTED_DIR)
unless system('ruby', CONVERT, EXPECTED_DIR, out: File::NULL)
  abort 'convert.rb failed; aborting check'
end

actual_names   = Dir.glob("#{ACTUAL_DIR}/*.md").map { |f| File.basename(f) }.to_set
expected_names = Dir.glob("#{EXPECTED_DIR}/*.md").map { |f| File.basename(f) }.to_set

# In PILOTS_ONLY mode, only compare pilot-dated actuals against expected.
if ENV['PILOTS_ONLY']
  pilot_dates = %w[2026-05-31 2026-02-01 2019-05-26]
  actual_names.select! { |n| pilot_dates.any? { |d| n.start_with?(d) } }
end

report = []
report << "=== CHECK REPORT — #{Time.now} ==="
report << "Actual:   #{ACTUAL_DIR}"
report << "Expected: #{EXPECTED_DIR}"
report << "Mode:     #{ENV['PILOTS_ONLY'] ? 'PILOTS_ONLY' : 'all'}"
report << ""

stats = Hash.new(0)

(actual_names & expected_names).sort.each do |name|
  a = File.read(File.join(ACTUAL_DIR, name))
  e = File.read(File.join(EXPECTED_DIR, name))
  if a == e
    stats[:clean] += 1
    report << "[CLEAN] #{name}"
  else
    stats[:diff] += 1
    report << "[DIFF]  #{name}"
    diff = `diff -u #{EXPECTED_DIR}/#{name} #{ACTUAL_DIR}/#{name}`
    diff.lines.drop(2).each { |l| report << "    #{l.chomp}" }
    report << ""
  end
end

(actual_names - expected_names).sort.each do |name|
  stats[:only_actual] += 1
  report << "[ONLY-ACTUAL] #{name}  (file in _concerts/ has no matching source chunk; possibly hand-authored or stale)"
end

(expected_names - actual_names).sort.each do |name|
  stats[:missing] += 1
  report << "[MISSING]     #{name}  (source chunk converted but no file in _concerts/)"
end

# --- No-fabrication pass: every non-blank body line in _concerts/*.md must exist
# verbatim somewhere in concerts/index.md (after NBSP normalization). Catches drift
# the regeneration check misses (shared converter bugs, hand-edits to body content).
report << ""
report << "=== NO-FABRICATION PASS ==="

source_lines = File.readlines(SOURCE_FILE).map { |l| normalize(l) }.to_set

actual_names.sort.each do |name|
  body = extract_body(File.join(ACTUAL_DIR, name))
  unmatched = []
  body.each_line do |line|
    n = normalize(line)
    next if n.empty?
    unmatched << line.chomp unless source_lines.include?(n)
  end

  if unmatched.empty?
    stats[:no_fab_clean] += 1
  else
    stats[:no_fab_drift] += 1
    report << "[FABRICATED] #{name}  (#{unmatched.size} body lines not found in source)"
    unmatched.each { |l| report << "    #{l}" }
    report << ""
  end
end

report << ""
report << "=== STATS ==="
report << "clean (byte-identical):     #{stats[:clean]}"
report << "diff (review needed):       #{stats[:diff]}"
report << "only-actual (unexpected):   #{stats[:only_actual]}"
report << "missing (not yet in repo):  #{stats[:missing]}"
report << "no-fab clean:               #{stats[:no_fab_clean]}"
report << "no-fab drift:               #{stats[:no_fab_drift]}"

File.write(REPORT_FILE, report.join("\n") + "\n")
puts "clean=#{stats[:clean]} diff=#{stats[:diff]} only-actual=#{stats[:only_actual]} missing=#{stats[:missing]}"
puts "See #{REPORT_FILE}"
