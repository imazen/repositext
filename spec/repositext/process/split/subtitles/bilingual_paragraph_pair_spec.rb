# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe BilingualParagraphPair do

          let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
          let(:primary_contents) { 'word1 word2 word3' }
          let(:foreign_language) { Language::Spanish.new }
          let(:primary_language) { Language::English.new }
          let(:foreign_paragraph) { Paragraph.new(foreign_contents, foreign_language) }
          let(:primary_paragraph) { Paragraph.new(primary_contents, primary_language) }
          let(:bilingual_paragraph_pair) { BilingualParagraphPair.new(primary_paragraph, foreign_paragraph) }

          describe '#aligned_text_pairs' do

            it "handles default data" do
              bilingual_paragraph_pair.aligned_text_pairs.map { |btp|
                [btp.primary_contents, btp.foreign_contents]
              }.must_equal([[primary_contents, foreign_contents]])
            end

          end

          describe '#confidence_stats' do

            it "handles default data" do
              bilingual_paragraph_pair.confidence_stats.must_equal(
                { max: 1.0, min: 1.0, mean: 1.0, median: 1.0, count: 1 }
              )
            end

          end

          describe '#compute_aligned_text_pairs' do

            it "handles default data" do
              bilingual_paragraph_pair.send(
                :compute_aligned_text_pairs,
                primary_paragraph,
                foreign_paragraph
              ).map { |btp|
                [btp.primary_contents, btp.foreign_contents]
              }.must_equal([[primary_contents, foreign_contents]])
            end

          end

          describe '#compute_raw_aligned_text_pairs' do

            it "handles default data" do
              bilingual_paragraph_pair.send(
                :compute_raw_aligned_text_pairs,
                primary_paragraph,
                foreign_paragraph
              ).map { |btp|
                [btp.primary_contents, btp.foreign_contents]
              }.must_equal([[primary_contents, foreign_contents]])
            end

            [
              [
                'word1 word2 word3 word4',
                'palabra1 palabra2 palabra3 palabra4',
                [
                  ["word1 word2 word3 word4", "palabra1 palabra2 palabra3 palabra4"]
                ],
                [1.0],
              ],
              [
                'word1 word2. word3 word4. word5 word6.',
                'palabra1 palabra2. palabra3 palabra4. palabra5 palabra6.',
                [
                  ["word1 word2.", "palabra1 palabra2."],
                  ["word3 word4.", "palabra3 palabra4."],
                  ["word5 word6.", "palabra5 palabra6."]
                ],
                [1.0, 1.0, 1.0],
              ],
              [
                'word1 word2. word3 word4. word5 word6.',
                'palabra1 palabra2. palabra3 palabra4.',
                [
                  ["word1 word2. word3 word4.", "palabra1 palabra2."],
                  ["word5 word6.", "palabra3 palabra4."]
                ],
                [0.5, 1.0],
              ],
            ].each { |(primary_contents, foreign_contents, xpect_contents, xpect_confidences)|
              it "handles #{ primary_contents.inspect }" do
                r = bilingual_paragraph_pair.send(
                  :compute_raw_aligned_text_pairs,
                  Paragraph.new(primary_contents, primary_language),
                  Paragraph.new(foreign_contents, foreign_language)
                )
                r.map { |btp|
                  [btp.primary_contents, btp.foreign_contents]
                }.must_equal(xpect_contents)
                r.map { |btp| btp.confidence }.must_equal(xpect_confidences)
              end
            }

          end

        end

      end
    end
  end
end
