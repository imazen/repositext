# Run this script to generate a text file with invalid UTF8 byte sequences:
#    ruby test_data/invalid/encoding/_generate_invalid_utf8_byte_sequences.rb

# This SO answer has some good points to include when testing invalid UTF8:
# http://stackoverflow.com/a/1319229/130830


[
  ['invalid_bytes_1', "\xC0"],
  ['invalid_bytes_2', "\xC1"],
  ['invalid_bytes_3', "\xF5"],
  ['invalid_bytes_4', "\xFF"],
  ['non_minimal_multi_byte_characters_1', "\xE0\x80\x80"],
  ['non_minimal_multi_byte_characters_2', "\xF0\x80\x80\x80"],
  ['utf_16_surrogates_1', "\xD8\x00"],
  ['utf_16_surrogates_2', "\xDF\xFF"]
].each do |string_with_invalid_utf8_byte_sequence|
  File.open(
    File.join(
      File.expand_path('..', __FILE__),
      "utf8_invalid_byte_sequence-#{ string_with_invalid_utf8_byte_sequence.first }.txt"
    ),
    'w'
  ) do |out|
    out << [
      "This file contains an invalid utf8 byte sequence",
      "================================================",
      "",
      string_with_invalid_utf8_byte_sequence.first.gsub('_', ' '),
      "",
      string_with_invalid_utf8_byte_sequence.last,
      ""
    ].join("\n")
  end
end
