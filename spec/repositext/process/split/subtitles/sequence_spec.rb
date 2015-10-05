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
