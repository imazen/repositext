=begin

This script compares various string similarity metrics to be used for
subtitle operation tracking.

=end

require 'amatch' # for string similarity algorithms
require 'rainbow/ext/string' # for coloured console output

string1 = "where more stress is laid perhaps upon the platitu" # green
string2 = "which to an observer contains the vital essence of" # red
string3 = "depend upon it there is nothing so unnatural as th" # blue

scenarios = [
  ["identical",                   [string2],                                [:red]],
  ["1 character changed (a)",     [string2[0, 5], 'tX', string2[9..-1]],    [:red, :blue, :red]],
  ["1 character changed (b)",     [string2[0, 29], 'tXe', string2[34..-1]], [:red, :blue, :red]],
  ["overlap (50%)",               [string2[-25..-1], string3[0..-27]],      [:red, :blue]],
  ["rotated (50%)",               [string2[-25..-1], string2[0..-27]],      [:red, :red]],
  ["left aligned superset",       [string2, string3],                       [:red, :blue]],
  ["right aligned superset",      [string1, string2],                       [:green, :red]],
  ["repetition",                  [string2, string2],                       [:red, :red]],
  ["overlap (25%)",               [string2[-13..-1], string3[0..-15]],      [:red, :blue]],
  ["overlap (3 chars)",           [string2[-3..-1], string3[0..-5]],        [:red, :blue]],
  ["different (s3)",              [string3],                                [:blue]],
  ["different (s1)",              [string1],                                [:green]],
]

similarity_algorithms = %w[
  longest_subsequence
  longest_substring
  hamming
  jaro
  jarowinkler
  levenshtein
  pair_distance
]

base_string = string2

output = ['', '', "Comparing".rjust(28) + " #{ base_string.color(:red) } with:", ('-' * 100)]

# Legend
scenarios.each { |(label, test_string, colors)|
  output << [
    label.rjust(28),
    ' ',
    test_string.each_with_index.map { |e, idx| e.color(colors[idx]) }.join(' ')
  ].join
}

# Similarities
output << ''
output << ["Test scenario".rjust(28), ' ', similarity_algorithms.map { |e| e.center(20) }.join].join

scenarios.each { |label, test_string|
  similarity_scores = similarity_algorithms.map { |algo|
    base_string.send("#{ algo }_similar", test_string.join(' '))
  }.map { |e|
    [
      ('█' * (e * 10).round).rjust(10),
      ' ',
      e.round(3)
    ].join.ljust(20)
  }
  output << [
    label.rjust(28),
    ' ',
    similarity_scores.join
  ].join
}

# Print to console
output.each { |e| puts e }; nil
