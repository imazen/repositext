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

      end
    end
  end
end
