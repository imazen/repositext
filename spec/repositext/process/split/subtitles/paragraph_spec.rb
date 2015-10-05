# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe Paragraph do

          let(:contents) { 'contents' }
          let(:language) { Language::English.new }
          let(:paragraph) { Paragraph.new(contents, language)}

          describe 'Initializing' do

            it "initializes contents" do
              paragraph.contents.must_equal(contents)
            end

            it "initializes language" do
              paragraph.language.must_equal(language)
            end

          end

          describe '#sentences' do

            [
              [%(word1 word2 word3. word4 word5 word6.), 2],
            ].each do |(txt, xpect)|
              it "handles #{ txt.inspect }" do
                t = Paragraph.new(txt, language)
                t.sentences.length.must_equal(xpect)
              end
            end

          end

          describe '#split_into_sentences' do
            [
              [
                %(word1 word2 word3. word4 word5 word6.),
                ['word1 word2 word3.', 'word4 word5 word6.']
              ],
            ].each do |(txt, xpect)|
              it "handles #{ txt.inspect }" do
                paragraph.send(
                  :split_into_sentences, txt, language
                ).map { |s| s.contents }.must_equal(xpect)
              end
            end
          end

          describe '#encode_contents_for_sentence_splitting' do
            [
              [%(word), 'word'],
              [%(word!, word), 'wordrtxt_excl_comm word'],
            ].each do |(txt, xpect)|
              it "handles #{ txt.inspect }" do
                paragraph.send(
                  :encode_contents_for_sentence_splitting, txt, language
                ).must_equal(xpect)
              end
            end
          end

          describe '#decode_contents_after_sentence_splitting' do
            [
              ['word', %(word)],
              ['wordrtxt_excl_comm word', %(word!, word)],
            ].each do |(txt, xpect)|
              it "handles #{ txt.inspect }" do
                paragraph.send(
                  :decode_contents_after_sentence_splitting, txt, language
                ).must_equal(xpect)
              end
            end
          end

        end

      end
    end
  end
end
