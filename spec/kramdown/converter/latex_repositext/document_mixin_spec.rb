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
              20,
              3,
              "\\emph{word} word"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2 word3 word4 word5}",
              20,
              3,
              "\\emph{word1 word2 word3…}"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2 word3 \\textscale{0.7}{word4 word5}}",
              20,
              3,
              "\\emph{word1 word2 word3…\\textscale{0.7}{}}"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2 \\textscale{0.7}{word3 word4 word5}}",
              20,
              3,
              "\\emph{word1 word2 \\textscale{0.7}{word3…}}"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2} \\emph{word3 word4 word5}",
              20,
              3,
              "\\emph{word1 word2} \\emph{word3…}"
            ],
            [
              "Word Word Word Word, Word Word Word Word Word Word Word Word Word Word Word Word",
              "\\emph{W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}, W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}}",
              20,
              3,
              "\\emph{W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}…\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}}"
            ],
            [
              "A Word Wording Word \nWord Word Word Word",
              "\\emph{A W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORDING} W\\RtSmCapsEmulation{ORD} \\linebreak\nW\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORD}}",
              20,
              3,
              "\\emph{A W\\RtSmCapsEmulation{ORD} W\\RtSmCapsEmulation{ORDING} W\\RtSmCapsEmulation{ORD}…\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}\\RtSmCapsEmulation{}}"
            ],
            [
              "word1 word2 word3 word4 word5",
              "\\emph{word1 word2 word3 word4 word5}",
              20,
              0,
              "\\emph{word1 word2 word3 w…}"
            ],
          ].each do |(title_plain_text, title_latex, max_len, min_length_of_last_word, xpect)|
            it "truncates #{ title_latex.inspect }" do
              converter = LatexRepositextPlain.send(:new, '_', {})
              converter.send(
                :compute_truncated_title,
                title_plain_text,
                title_latex,
                max_len,
                min_length_of_last_word
              ).must_equal(xpect)
            end
          end
        end
      end
    end
  end
end
