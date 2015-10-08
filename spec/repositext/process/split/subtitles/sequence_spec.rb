# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe Sequence do

          let(:contents) { 'contents' }
          let(:language) { Language::English.new }

          describe 'Initializing' do

            it "initializes contents" do
              t = Sequence.new(contents, language)
              t.contents.must_equal(contents)
            end

            it "initializes language" do
              t = Sequence.new(contents, language)
              t.language.must_equal(language)
            end

          end

          describe '#paragraphs' do
            [
              [%(word1 word2 word3\nword4 word5 word6), 2],
            ].each do |(txt, xpect)|
              it "handles #{ txt.inspect }" do
                t = Sequence.new(txt, language)
                t.paragraphs.length.must_equal(xpect)
              end
            end
          end

          describe '#as_kramdown_doc' do

            it "converts self to kramdown doc" do
              t = Sequence.new("# the title\nAnd a paragraph\n", language)
              t.as_kramdown_doc.root.inspect_tree.must_equal(
                %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}
                     - :header - {:level=>1, :raw_text=>\"the title\", :location=>1}
                       - :text - {:location=>1} - \"the title\"
                     - :p - {:location=>2}
                       - :text - {:location=>2} - \"And a paragraph\"
                  ).gsub(/\n                  /, "\n")
              )
            end

          end

          describe '#split_into_paragraphs' do
            [
              [
                %(word1 word2 word3\nword4 word5 word6),
                ['word1 word2 word3', 'word4 word5 word6']
              ],
            ].each do |(txt, xpect)|
              it "handles #{ txt.inspect }" do
                t = Sequence.new(txt, language)
                t.paragraphs.map { |para| para.contents }.must_equal(xpect)
              end
            end
          end

        end

      end
    end
  end
end
