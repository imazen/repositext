require_relative '../../../helper'

module Kramdown
  module Converter
    class LatexRepositext
      # We test it as part of LatexRepositextPlain (includes DocumentMixin)
      describe DocumentMixin do

        describe "#compute_truncated_title" do
          [
            [
              "word word",
              "\\emph{word} word",
              "\\emph{word} word"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2 word3 word4 word5}",
              "\\emph{word1 word2 word3…}"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2 word3 \\textscale{0.7}{word4 word5}}",
              "\\emph{word1 word2 word3…\\textscale{0.7}{}}"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2 \\textscale{0.7}{word3 word4 word5}}",
              "\\emph{word1 word2 \\textscale{0.7}{word3…}}"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2} \\emph{word3 word4 word5}",
              "\\emph{word1 word2} \\emph{word3…}"
            ],
            [
              "Word Word Word Word, Word Word Word Word Word Word Word Word Word Word Word Word",
              "\\emph{W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}, W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}}",
              "\\emph{W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}…\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}}"
            ],
            [
              "A Word Wording Word \nWord Word Word Word",
              "\\emph{A W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORDING} W\\RtSmCapsEmulation{ORD} \\linebreak\nW\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}}",
              "\\emph{A W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORDING} W\\RtSmCapsEmulation{ORD}…\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}}"
            ],
          ].each do |(title_plain_text, title_latex, xpect)|
            it "truncates #{ title_latex.inspect }" do
              converter = LatexRepositextPlain.send(:new, '_', {})
              converter.send(
                :compute_truncated_title,
                title_plain_text,
                title_latex,
                20,
                0
              ).must_equal(xpect)
            end
          end
        end

        describe "#compute_vspace_between_title_text_and_hrule" do
          [
            ["\\emph{no comma word word}", 6.733],
            ["\\emph{comma on single line W\\RtSmCapsEmulation{ORD}, W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}}", 3.1939999999999995],
            ["\\emph{comma on last of multiple lines W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} \\linebreak\n\\emph{W\\RtSmCapsEmulation{ORD}, W\\RtSmCapsEmulation{ORD}}", 3.1939999999999995],
            ["\\emph{comma on first of multiple lines W\\RtSmCapsEmulation{ORD}, W\\RtSmCapsEmulation{ORD} \\linebreak\n\\emph{W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}}", 6.733],
          ].each do |test_string, xpect|
            it "handles #{ test_string }" do
              converter = LatexRepositextPlain.send(:new, '_', {})
              converter.send(
                :compute_vspace_between_title_text_and_hrule,
                test_string
              ).must_equal(xpect)
            end
          end
        end
      end
    end
  end
end
