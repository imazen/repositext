# require_relative '../../helper'

# module Kramdown
#   module Converter
#     describe LatexRepositext do

#       describe "#convert_entity" do

#         [
#           ["word &amp; word", "word \\&{} word\n\n"],
#           ["word &#x2011; word", "word \u2011 word\n\n"],
#           ["word &#x2028; word", "word \u2028 word\n\n"],
#           ["word &#x202F; word", "word \u202F word\n\n"],
#           ["word &#xFEFF; word", "word \uFEFF word\n\n"],
#         ].each do |test_string, xpect|
#           it "decodes valid encoded entity #{ test_string.inspect }" do
#             doc = Document.new(test_string, :input => 'KramdownRepositext')
#             doc.to_latex_repositext.must_equal(xpect)
#           end
#         end

#         [
#           ["word &#x2012; word", "word  word\n\n"],
#         ].each do |test_string, xpect|
#           it "doesn't decode invalid encoded entity #{ test_string.inspect }" do
#             doc = Document.new(test_string, :input => 'KramdownRepositext')
#             doc.to_latex_repositext.must_equal(xpect)
#           end
#         end

#         [
#           ["word &#x391; word", "word $A${} word\n\n"], # decimal 913
#         ].each do |test_string, xpect|
#           it "decodes kramdown built in entity #{ test_string.inspect }" do
#             doc = Document.new(test_string, :input => 'KramdownRepositext')
#             doc.to_latex_repositext.must_equal(xpect)
#           end
#         end

#       end

#       describe "#escape_latex_text" do

#         [
#           ["word & word", "word \\& word"],
#           ["word % word", "word \\% word"],
#           ["word $ word", "word \\$ word"],
#           ["word # word", "word \\# word"],
#           ["word _ word", "word \\_ word"],
#           ["word { word", "word \\{ word"],
#           ["word } word", "word \\} word"],
#           ["word ~ word", "word \\textasciitilde word"],
#           ["word ^ word", "word \\textasciicircum word"],
#         ].each do |test_string, xpect|
#           it "escapes #{ test_string.inspect }" do
#             c = LatexRepositext.send(:new, '_', {})
#             c.send(:escape_latex_text, test_string).must_equal(xpect)
#           end
#         end

#         [
#           ["word \\& word", "word \\& word"],
#           ["word \\% word", "word \\% word"],
#           ["word \\$ word", "word \\$ word"],
#           ["word \\# word", "word \\# word"],
#           ["word \\_ word", "word \\_ word"],
#           ["word \\{ word", "word \\{ word"],
#           ["word \\} word", "word \\} word"],
#         ].each do |test_string, xpect|
#           it "does not escape already escaped character #{ test_string.inspect }" do
#             c = LatexRepositext.send(:new, '_', {})
#             c.send(:escape_latex_text, test_string).must_equal(xpect)
#           end
#         end

#       end

#       describe "#post_process_latex_body" do

#         [
#           ["<<<gap-mark>>>word1 word2", "\\RtGapMarkText{}\\RtGapMarkText{word1} word2"], # first word after gap_mark colored red
#           *[
#             Repositext::D_QUOTE_OPEN,
#             Repositext::EM_DASH,
#             Repositext::S_QUOTE_OPEN,
#             ' ',
#             '(',
#             '[',
#             '"',
#             "'",
#             '}',
#             '*',
#           ].map { |c|
#             # skip certain chars when coloring red
#             ["<<<gap-mark>>>#{ c }word1 word2", "\\RtGapMarkText{}#{ c }\\RtGapMarkText{word1} word2"]
#           },
#           ["<<<gap-mark>>>word1 word2", "\\RtGapMarkText{}\\RtGapMarkText{word1} word2"], # first word after gap_mark colored red
#           ["<<<gap-mark>>>\\emph{word1 word2} word3", "\\RtGapMarkText{}\\emph{\\RtGapMarkText{word1} word2} word3"], # first word in \em after gap_mark colored red
#           ["<<<gap-mark>>>…\\emph{word1}", "\\RtGapMarkText{…}\\emph{\\RtGapMarkText{word1}}"], # ellipsis and first word in \em after gap_mark colored red
#           ["<<<gap-mark>>> word1 word2", "\\RtGapMarkText{}\\RtEagle\\ \\RtGapMarkText{word1} word2"], # eagle followed by whitespace not red
#           ["<<<gap-mark>>>…word1 word2", "\\RtGapMarkText{…}\\RtGapMarkText{word1} word2"], # ellipsis and first word after gap_mark colored red
#           ["<<<gap-mark>>>word1… word2", "\\RtGapMarkText{}\\RtGapMarkText{word1}… word2"], # ellipsis after first word after gap_mark is not red
#           ["\n\n<<<gap-mark>>>\\textit{\\textbf{“word", "\n\n\\RtGapMarkText{}\\textit{\\textbf{“\\RtGapMarkText{word}"], # replace gap-marks before nested latex commands and skip chars
#           ["<<<gap-mark>>>(\\emph{others}", "\\RtGapMarkText{}(\\emph{\\RtGapMarkText{others}}"], # replace gap-marks before nested latex commands and skip chars
#         ].each do |test_string, xpect|
#           it "handles #{ test_string.inspect }" do
#             c = LatexRepositext.send(:new, '_', {})
#             c.send(:post_process_latex_body, test_string).must_equal(xpect)
#           end
#         end

#         it "adds a tilde between double open quote and apostrophe to avoid line breaks" do
#           c = LatexRepositext.send(:new, '_', {})
#           c.send(
#             :post_process_latex_body,
#             "#{ Repositext::D_QUOTE_OPEN } #{ Repositext::APOSTROPHE }"
#           ).must_equal(
#             "#{ Repositext::D_QUOTE_OPEN }~#{ Repositext::APOSTROPHE }"
#           )
#         end
#       end

#     end
#   end
# end
