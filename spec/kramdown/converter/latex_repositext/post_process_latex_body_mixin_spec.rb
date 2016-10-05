require_relative '../../../helper'

module Kramdown
  module Converter
    class LatexRepositext
      describe PostProcessLatexBodyMixin do

        describe '#highlight_gap_marks_in_red!' do
          [
            # color first word after gap_mark red
            ["<<<gap-mark>>>word1 word2", "\\RtGapMarkText{word1} word2"],
            *[
              Repositext::D_QUOTE_OPEN,
              Repositext::EM_DASH,
              Repositext::S_QUOTE_OPEN,
              ' ',
              '(',
              '[',
              '"',
              "'",
              '}',
              '*',
              '［', # chinese bracket
              '（', # chinese parens
              '一', # chinese dash
              '《', # chinese left double angle bracket
              '……', # chinese double ellipsis
            ].map { |c|
              # skip certain chars when coloring red
              ["<<<gap-mark>>>#{ c }word1 word2", "#{ c }\\RtGapMarkText{word1} word2"]
            },
            ["<<<gap-mark>>>word1 word2", "\\RtGapMarkText{word1} word2"], # first word after gap_mark colored red
            ["<<<gap-mark>>>\\emph{word1 word2} word3", "\\emph{\\RtGapMarkText{word1} word2} word3"], # first word in \em after gap_mark colored red
            ["<<<gap-mark>>>…\\emph{word1}", "\\RtGapMarkText{…}\\emph{\\RtGapMarkText{word1}}"], # elipsis and first word in \em after gap_mark colored red
            ["<<<gap-mark>>> word1 word2", " \\RtGapMarkText{word1} word2"], # eagle followed by whitespace not red
            ["<<<gap-mark>>>…word1 word2", "\\RtGapMarkText{…}\\RtGapMarkText{word1} word2"], # elipsis and first word after gap_mark colored red
            ["<<<gap-mark>>>word1… word2", "\\RtGapMarkText{word1}… word2"], # elipsis after first word after gap_mark is not red
            ["\n\n<<<gap-mark>>>\\textit{\\textbf{“word", "\n\n\\textit{\\textbf{“\\RtGapMarkText{word}"], # replace gap-marks before nested latex commands and skip chars
            ["<<<gap-mark>>>(\\emph{others}", "(\\emph{\\RtGapMarkText{others}}"], # replace gap-marks before nested latex commands and skip chars
            ["<<<gap-mark>>>#{ Repositext::EM_DASH }word1 word2", "#{ Repositext::EM_DASH }\\RtGapMarkText{word1} word2"],
            ["<<<gap-mark>>>\\emph{…}word1 \\emph{word2}", "\\emph{\\RtGapMarkText{…}}word1 \\emph{word2}"],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              c = LatexRepositext.send(:new, '_', {})
              c.send(:highlight_gap_marks_in_red!, test_string)
              test_string.must_equal(xpect)
            end
          end
        end

        describe '#format_leading_and_trailing_eagles!' do
          [
            # Replace leading eagle with latex environment
            ["first para\n second para word1 word2 word3\nthird para", "first para\n\\RtFirstEagle second para word1 word2 word3\nthird para"],
            [" \\RtGapMarkText{First} para word1 word2 word3", "\\RtFirstEagle \\RtGapMarkText{First} para word1 word2 word3"],
            # Replace trailing eagle with latex command
            ["Second to last para\nLast para word1 word2 word3 \n{: .normal}", "Second to last para\nLast para word1 word2 word3\\RtLastEagle{}\n{: .normal}"],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              c = LatexRepositext.send(:new, '_', {})
              c.send(:format_leading_and_trailing_eagles!, test_string)
              test_string.must_equal(xpect)
            end
          end
        end

        describe '#remove_space_after_paragraph_numbers!' do
          [
            ["\\RtParagraphNumber{123} word", "\\RtParagraphNumber{123}word"],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              c = LatexRepositext.send(:new, '_', {})
              c.send(:remove_space_after_paragraph_numbers!, test_string)
              test_string.must_equal(xpect)
            end
          end
        end

        describe '#set_line_break_positions!' do
          [
            # Insert zero width space after line_breakable_chars (elipsis, em-dash, and hyphen), except when followed by certain characters
            ["word1 word2#{ Repositext::ELIPSIS }word3 word4", "word1 word2\\nolinebreak[4]#{ Repositext::ELIPSIS }\\hspace{0pt}word3 word4"],
            ["word1 word2#{ Repositext::EM_DASH }word3 word4", "word1 word2\\nolinebreak[4]#{ Repositext::EM_DASH }\\hspace{0pt}word3 word4"],
            ["word1 word2-word3 word4", "word1 word2\\nolinebreak[4]-\\hspace{0pt}word3 word4"],
            ["word1 word2#{ Repositext::ELIPSIS }! word3 word4", "word1 word2#{ Repositext::ELIPSIS }! word3 word4"],
            ["word1 word2#{ Repositext::EM_DASH }! word3 word4", "word1 word2#{ Repositext::EM_DASH }! word3 word4"],
            ["word1 word2-! word3 word4", "word1 word2-! word3 word4"],
            ["word1 word2-ed. word3 word4", "word1 word2-ed. word3 word4"],
            ["\\RtGapMarkText{…}\\emph{\\RtGapMarkText{word1}}", "\\RtGapMarkText{\\nolinebreak[4]…\\hspace{0pt}}\\emph{\\RtGapMarkText{word1}}"], #
            # Don't insert zero width space before certain punctuation
            ["word1 word2-#{ Repositext::S_QUOTE_CLOSE }word3 word4", "word1 word2-#{ Repositext::S_QUOTE_CLOSE }word3 word4"],
            ["word1 word2-#{ Repositext::D_QUOTE_CLOSE }word3 word4", "word1 word2-#{ Repositext::D_QUOTE_CLOSE }word3 word4"],
            # No line breaks _before_ or _after_ em dash when followed by some abbreviations
            ["word1 word2#{ Repositext::EM_DASH }ed. word3 word4", "word1 word2\\nolinebreak[4]#{ Repositext::EM_DASH }\\nolinebreak[4]ed. word3 word4"],
            # No line breaks before certain numbers
            ["word 4", "word~4"],
            ["word 4:5", "word~4:5"],
            ["word 42:52", "word~42:52"],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              c = LatexRepositext.send(:new, '_', { ed_and_trn_abbreviations: "ed\\." })
              c.send(:set_line_break_positions!, test_string)
              test_string.must_equal(xpect)
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
end
