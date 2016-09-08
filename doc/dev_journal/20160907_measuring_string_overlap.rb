=begin

This script explores an approach to measuring string overlap.

=end

require 'amatch' # for string similarity algorithms
require 'rainbow/ext/string' # for coloured console output

start = "this is the start of the string."
overlap = "Here comes the overlapping portion."
ending = "And the last bit is the ending of the string."

scenarios = [
  [
    "50% identical overlap",
    [start, overlap].join(' '),
    [overlap, ending].join(' '),
  ],
  [
    "No overlap",
    start,
    ending
  ],
  [
    "5 char overlap",
    [start, '12345'].join(' '),
    ['12345', ending].join(' '),
  ],
  [
    "Test1",
    "I don’t think you have any books. Is that right, Leo? Don’t have no books, ",
    "Don’t have no books, but you still have tapes and a few of the pictures left, ",
  ],
  [
    "Test2",
    "[Blank spot on tape. End of record—Ed.]… If you have faith, ",
    "[End of record—Ed.]… If you have faith, I want to ask you and show you, rather, that—that you do not have faith. ",
  ],

]

# This method measures the overlap of two strings by counting the number of
# characters that can overlap while longest common subsequence is greater 0.9
# It assumes that string_a's end overlaps with string_b's start.
def measure_string_overlap(string_a, string_b)
  overlap = 3
  lcs = 1.0
  min_string_length = [string_a, string_b].map(&:length).min
  prev_sim = 0
  max_sim = 0
  overall_sim = string_a.longest_subsequence_similar(string_b)
  puts "Overall similarity: #{ overall_sim.round(3) }"
  similarity_threshold = 0.95

  until(
    1.0 == max_sim ||
    (overlap > 5 && max_sim >= similarity_threshold) ||
    overlap >= min_string_length
  ) do
    puts ''
    string_a_end = string_a[-overlap..-1]
    string_b_start = string_b[0..(overlap-1)]
    sim = string_a_end.longest_subsequence_similar(string_b_start)
    puts [
      ('█' * (sim * 10).round).rjust(10),
      ' ',
      string_a_end.inspect
    ].join
    puts [
      sim.round(3).to_s.rjust(10).color(prev_sim <= sim ? :green : :red),
      ' ',
      string_b_start.inspect
    ].join
    if sim > max_sim
      optimal_overlap = overlap
    end
    max_sim = [max_sim, sim].max
    prev_sim = sim
    overlap += 1
  end
  if max_sim > similarity_threshold
    optimal_overlap
  else
    0
  end
end

scenarios.each do |desc, s1, s2|
  puts ''
  puts "Scenario: #{ desc }"
  puts '=' * 100
  puts "s1: #{ s1.inspect }"
  puts "s2: #{ s2.inspect }"
  r = measure_string_overlap(s1, s2)
  puts "Computed overlap: #{ r.inspect }"
end

