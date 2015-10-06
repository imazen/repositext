# encoding UTF-8
require_relative '../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles

        describe BilingualSequencePair do

          let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
          let(:primary_contents) { 'word1 word2 word3' }
          let(:foreign_language) { Language::Spanish.new }
          let(:primary_language) { Language::English.new }
          let(:foreign_sequence) { Sequence.new(foreign_contents, foreign_language) }
          let(:primary_sequence) { Sequence.new(primary_contents, primary_language) }
          let(:bilingual_sequence_pair) { BilingualSequencePair.new(primary_sequence, foreign_sequence) }

          describe '#aligned_paragraph_pairs' do

            it "handles default data" do
              bilingual_sequence_pair.aligned_paragraph_pairs.map { |bpp|
                bpp.aligned_text_pairs.map { |btp|
                  [btp.primary_contents, btp.foreign_contents]
                }
              }.must_equal([[[primary_contents, foreign_contents]]])
            end

          end

          describe '#confidence_stats' do

            it "handles default data" do
              bilingual_sequence_pair.confidence_stats.must_equal(
                { max: 1.0, min: 1.0, mean: 1.0, median: 1.0, count: 1 }
              )
            end

          end

          describe '#compute_aligned_paragraph_pairs' do

            it "handles default data" do
              bilingual_sequence_pair.send(
                :compute_aligned_paragraph_pairs,
                primary_sequence,
                foreign_sequence
              ).map { |bpp|
                bpp.aligned_text_pairs.map { |btp|
                  [btp.primary_contents, btp.foreign_contents]
                }
              }.must_equal([[[primary_contents, foreign_contents]]])
            end

          end

          describe 'Spanish' do

            let(:specific_foreign_language) { Language::Spanish.new }

            [
              [
                '53-0609a para 88 etc.',
                '88 palabra palabra, palabra palabra: “palabra palabra palabra palabra palabra palabra palabra, palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra; ¡palabra palabra palabra palabra palabra!”. ¡palabra!',
                '@88 word word, word word, “word word word word word word word, @word word word word word word word word word word word. @word word word word!” word!',
                [
                  [
                    [
                      "@88 word word, word word, “word word word word word word word, @word word word word word word word word word word word. @word word word word!” word!",
                      "88 palabra palabra, palabra palabra: “palabra palabra palabra palabra palabra palabra palabra, palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra palabra; ¡palabra palabra palabra palabra palabra!”. ¡palabra!"
                    ]
                  ]
                ],
              ],
            ].each do |desc, foreign_contents, primary_contents, xpect|

              it "handles #{ desc.inspect }" do
                foreign_sequence = Sequence.new(foreign_contents, specific_foreign_language)
                primary_sequence = Sequence.new(primary_contents, primary_language)
                r = BilingualSequencePair.new(primary_sequence, foreign_sequence).aligned_paragraph_pairs
                r.map { |bilingual_paragraph_pair|
                  bilingual_paragraph_pair.aligned_text_pairs.map { |bilingual_text_pair|
                    [bilingual_text_pair.primary_text.contents, bilingual_text_pair.foreign_text.contents]
                  }
                }.must_equal(xpect)
              end

            end

          end

        end

      end
    end
  end
end
