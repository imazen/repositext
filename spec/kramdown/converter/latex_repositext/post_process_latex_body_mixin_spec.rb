require_relative '../../../helper'

module Kramdown
  module Converter
    class LatexRepositext
      describe PostProcessLatexBodyMixin do

        language = Repositext::Language::English

        describe '#highlight_gap_marks_in_red!' do
          [
            # color first word after gap_mark red
            ["<<<gap-mark>>>word1 word2", "\\RtGapMarkText{word1} word2"],
            *[
              language.chars[:d_quote_open],
              language.chars[:em_dash],
              language.chars[:s_quote_open],
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
            ["<<<gap-mark>>>#{ language.chars[:em_dash] }word1 word2", "#{ language.chars[:em_dash] }\\RtGapMarkText{word1} word2"],
            ["<<<gap-mark>>>\\emph{…}word1 \\emph{word2}", "\\emph{\\RtGapMarkText{…}}word1 \\emph{word2}"],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              c = LatexRepositext.send(:new, '_', { language: language })
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
              c = LatexRepositext.send(:new, '_', { language: language })
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
              c = LatexRepositext.send(:new, '_', { language: language })
              c.send(:remove_space_after_paragraph_numbers!, test_string)
              test_string.must_equal(xpect)
            end
          end
        end

        describe '#set_line_break_positions!' do
          [
            # Insert zero width space after line_breakable_chars
            # (elipsis, em-dash, and hyphen), except when followed by certain characters.
            [
              "word1 word2#{ language.chars[:elipsis] }word3 word4",
              "word1 word2\\nolinebreak[4]#{ language.chars[:elipsis] }\\hspace{0pt}word3 word4"
            ],
            [
              "word1 word2#{ language.chars[:em_dash] }word3 word4",
              "word1 word2\\nolinebreak[4]#{ language.chars[:em_dash] }\\hspace{0pt}word3 word4"
            ],
            [
              "word1 word2-word3 word4",
              "word1 word2\\nolinebreak[4]-\\hspace{0pt}word3 word4"
            ],
            [
              "word1 word2#{ language.chars[:elipsis] }! word3 word4",
              "word1 word2#{ language.chars[:elipsis] }! word3 word4"
            ],
            [
              "word1 word2#{ language.chars[:em_dash] }! word3 word4",
              "word1 word2#{ language.chars[:em_dash] }! word3 word4"
            ],
            [
              "word1 word2-! word3 word4",
              "word1 word2-! word3 word4"
            ],
            [
              "word1 word2{-0.05em}word3 word4",
              "word1 word2{-0.05em}word3 word4"
            ],
            [
              "word1 word2-ed. word3 word4",
              "word1 word2-ed. word3 word4"
            ],
            [
              "\\RtGapMarkText{…}\\emph{\\RtGapMarkText{word1}}",
              "\\RtGapMarkText{\\nolinebreak[4]…\\hspace{0pt}}\\emph{\\RtGapMarkText{word1}}"
            ],
            # Don't insert zero width space before certain characters
            [
              "word1 word2-#{ language.chars[:s_quote_close] }word3 word4",
              "word1 word2-#{ language.chars[:s_quote_close] }word3 word4"
            ],
            [
              "word1 word2-#{ language.chars[:d_quote_close] }word3 word4",
              "word1 word2-#{ language.chars[:d_quote_close] }word3 word4"
            ],
            [
              "word1-) word2",
              "word1-) word2"
            ],
            [
              "word1-? word2",
              "word1-? word2"
            ],
            [
              "word1-, word2",
              "word1-, word2"
            ],
            [
              "word1-! word2",
              "word1-! word2"
            ],
            [
              "word1-\u00A0 word2",
              "word1-\u00A0 word2"
            ],
            [
              "word1-\u202F word2",
              "word1-\u202F word2"
            ],
            # No line breaks _before_ or _after_ em dash when followed by some abbreviations
            [
              "word1 word2#{ language.chars[:em_dash] }ed. word3 word4",
              "word1 word2\\nolinebreak[4]#{ language.chars[:em_dash] }\\nolinebreak[4]ed. word3 word4"
            ],
            # No line breaks before certain numbers
            [
              "word 4",
              "word~4"
            ],
            [
              "word 4:5",
              "word~4:5"
            ],
            [
              "word 42:52",
              "word~42:52"
            ],
            # No linebreaks between period and digits
            [
              "word .22 word",
              "word .\\nolinebreak[4]22 word"
            ],
            # No linebreak between chinese period and closing bracket
            [
              "word。] word",
              "word。\\nolinebreak[4]] word"
            ],
            # No linebreak between end of latex control sequence and period.
            [
              # Word a.d.
              "Word \\RtSmCapsEmulation{none}{A}{-0.1em}.\\RtSmCapsEmulation{none}{D}{-0.1em}.",
              "Word \\RtSmCapsEmulation{none}{A}{-0.1em}\\nolinebreak[4].\\RtSmCapsEmulation{none}{D}{-0.1em}\\nolinebreak[4]."
            ],
            [
              # Word Word. Word
              "Word \\RtGapMarkText{Word}. Word",
              "Word \\RtGapMarkText{Word}\\nolinebreak[4]. Word"
            ],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              c = LatexRepositext.send(:new, '_', { ed_and_trn_abbreviations: "ed\\.", language: language })
              c.send(:set_line_break_positions!, test_string)
              test_string.must_equal(xpect)
            end
          end

          it "adds a tilde between double open quote and apostrophe to avoid line breaks" do
            c = LatexRepositext.send(:new, '_', { language: language })
            c.send(
              :post_process_latex_body,
              "#{ language.chars[:d_quote_open] } #{ language.chars[:apostrophe] }"
            ).must_equal(
              "#{ language.chars[:d_quote_open] }~#{ language.chars[:apostrophe] }"
            )
          end

        end

      end
    end
  end
end
