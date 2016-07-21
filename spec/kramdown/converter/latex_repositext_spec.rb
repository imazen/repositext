require_relative '../../helper'

module Kramdown
  module Converter
    describe LatexRepositext do

      describe "#emulate_small_caps" do

        [
          ["Word Word", "W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}"],
          ["Wêrd Wêrd", "W\\RtSmCapsEmulation{ÊRD} W\\RtSmCapsEmulation{ÊRD}"],
          ["Word. Word,", "W\\RtSmCapsEmulation{ORD.} W\\RtSmCapsEmulation{ORD},"],
        ].each do |test_string, xpect|
          it "emulates small caps for #{ test_string.inspect }" do
            LatexRepositext.emulate_small_caps(test_string).must_equal(xpect)
          end
        end

      end

      describe "#convert_entity" do

        [
          ["word &amp; word", "word \\&{} word\n\n"],
          ["word &#x2011; word", "word \u2011 word\n\n"],
          ["word &#x2028; word", "word \u2028 word\n\n"],
          ["word &#x202F; word", "word \u202F word\n\n"],
          ["word &#xFEFF; word", "word \uFEFF word\n\n"],
        ].each do |test_string, xpect|
          it "decodes valid encoded entity #{ test_string.inspect }" do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x2012; word", "word  word\n\n"],
        ].each do |test_string, xpect|
          it "doesn't decode invalid encoded entity #{ test_string.inspect }" do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

        [
          ["word &#x391; word", "word $A${} word\n\n"], # decimal 913
        ].each do |test_string, xpect|
          it "decodes kramdown built in entity #{ test_string.inspect }" do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_latex_repositext.must_equal(xpect)
          end
        end

      end

      describe "#escape_latex_text" do

        [
          ["word & word", "word \\& word"],
          ["word % word", "word \\% word"],
          ["word $ word", "word \\$ word"],
          ["word # word", "word \\# word"],
          ["word _ word", "word \\_ word"],
          ["word { word", "word \\{ word"],
          ["word } word", "word \\} word"],
          ["word ~ word", "word \\textasciitilde word"],
          ["word ^ word", "word \\textasciicircum word"],
        ].each do |test_string, xpect|
          it "escapes #{ test_string.inspect }" do
            c = LatexRepositext.send(:new, '_', {})
            c.send(:escape_latex_text, test_string).must_equal(xpect)
          end
        end

        [
          ["word \\& word", "word \\& word"],
          ["word \\% word", "word \\% word"],
          ["word \\$ word", "word \\$ word"],
          ["word \\# word", "word \\# word"],
          ["word \\_ word", "word \\_ word"],
          ["word \\{ word", "word \\{ word"],
          ["word \\} word", "word \\} word"],
        ].each do |test_string, xpect|
          it "does not escape already escaped character #{ test_string.inspect }" do
            c = LatexRepositext.send(:new, '_', {})
            c.send(:escape_latex_text, test_string).must_equal(xpect)
          end
        end

      end

      describe "#post_process_latex_body" do

        [
          # color first word after gap_mark red
          ["<<<gap-mark>>>word1 word2", "\\RtGapMarkText{word1} word2"],
          *[
            Repositext::D_QUOTE_OPEN,
            Repositext::S_QUOTE_OPEN,
            ' ',
            '(',
            '[',
            '"',
            "'",
            '}',
            '*',
          ].map { |c|
            # skip certain chars when coloring red
            ["<<<gap-mark>>>#{ c }word1 word2", "#{ c }\\RtGapMarkText{word1} word2"]
          },
          ["<<<gap-mark>>>word1 word2", "\\RtGapMarkText{word1} word2"], # first word after gap_mark colored red
          ["<<<gap-mark>>>\\emph{word1 word2} word3", "\\emph{\\RtGapMarkText{word1} word2} word3"], # first word in \em after gap_mark colored red
          ["<<<gap-mark>>>…\\emph{word1}", "\\RtGapMarkText{\\nolinebreak[4]…\\hspace{0pt}}\\emph{\\RtGapMarkText{word1}}"], # elipsis and first word in \em after gap_mark colored red
          ["<<<gap-mark>>> word1 word2", "\\RtFirstEagle \\RtGapMarkText{word1} word2"], # eagle followed by whitespace not red
          ["<<<gap-mark>>>…word1 word2", "\\RtGapMarkText{\\nolinebreak[4]…\\hspace{0pt}}\\RtGapMarkText{word1} word2"], # elipsis and first word after gap_mark colored red
          ["<<<gap-mark>>>word1… word2", "\\RtGapMarkText{word1}\\nolinebreak[4]…\\hspace{0pt} word2"], # elipsis after first word after gap_mark is not red
          ["\n\n<<<gap-mark>>>\\textit{\\textbf{“word", "\n\n\\textit{\\textbf{“\\RtGapMarkText{word}"], # replace gap-marks before nested latex commands and skip chars
          ["<<<gap-mark>>>(\\emph{others}", "(\\emph{\\RtGapMarkText{others}}"], # replace gap-marks before nested latex commands and skip chars
          ["<<<gap-mark>>>#{ Repositext::EM_DASH }word1 word2", "\\nolinebreak[4]#{ Repositext::EM_DASH }\\hspace{0pt}\\RtGapMarkText{word1} word2"],
          # Insert zero width space after elipsis, em-dash, and hyphen
          ["word1 word2#{ Repositext::ELIPSIS }word3 word4", "word1 word2\\nolinebreak[4]#{ Repositext::ELIPSIS }\\hspace{0pt}word3 word4"],
          ["word1 word2#{ Repositext::EM_DASH }word3 word4", "word1 word2\\nolinebreak[4]#{ Repositext::EM_DASH }\\hspace{0pt}word3 word4"],
          ["word1 word2-word3 word4", "word1 word2\\nolinebreak[4]-\\hspace{0pt}word3 word4"],
          # Don't insert zero width space before certain punctuation
          ["word1 word2-#{ Repositext::S_QUOTE_CLOSE }word3 word4", "word1 word2-#{ Repositext::S_QUOTE_CLOSE }word3 word4"],
          ["word1 word2-#{ Repositext::D_QUOTE_CLOSE }word3 word4", "word1 word2-#{ Repositext::D_QUOTE_CLOSE }word3 word4"],
          # Replace leading eagle with latex environment
          ["first para\n second para word1 word2 word3\nthird para", "first para\n\\RtFirstEagle second para word1 word2 word3\nthird para"],
          ["<<<gap-mark>>> First para word1 word2 word3", "\\RtFirstEagle \\RtGapMarkText{First} para word1 word2 word3"],
          # Replace trailing eagle with latex command
          ["Second to last para\nLast para word1 word2 word3\n{: .normal}", "Second to last para\nLast para word1 word2 word3 \\RtLastEagle{}\n{: .normal}"],
        ].each do |test_string, xpect|
          it "handles #{ test_string.inspect }" do
            c = LatexRepositext.send(:new, '_', {})
            c.send(:post_process_latex_body, test_string).must_equal(xpect)
          end
        end

        it "adds a tilde between double open quote and apostrophe to avoid line breaks" do
          c = LatexRepositext.send(:new, '_', {})
          c.send(
            :post_process_latex_body,
            "#{ Repositext::D_QUOTE_OPEN } #{ Repositext::APOSTROPHE }"
          ).must_equal(
            "#{ Repositext::D_QUOTE_OPEN }~#{ Repositext::APOSTROPHE }"
          )
        end
      end

    end
  end
end
