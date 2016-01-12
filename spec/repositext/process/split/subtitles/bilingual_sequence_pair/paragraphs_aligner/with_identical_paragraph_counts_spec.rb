# encoding UTF-8
require_relative '../../../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair
          class ParagraphsAligner

            describe WithIdenticalParagraphCounts do

              let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
              let(:primary_contents) { 'word1 word2 word3' }
              let(:foreign_language) { Language::Spanish.new }
              let(:primary_language) { Language::English.new }
              let(:foreign_sequence) { Sequence.new(foreign_contents, foreign_language) }
              let(:primary_sequence) { Sequence.new(primary_contents, primary_language) }
              let(:paragraphs_aligner) { ParagraphsAligner.new(primary_sequence, foreign_sequence) }
              let(:structural_similarity) { paragraphs_aligner.structural_similarity }
              let(:with_identical_paragraph_counts) {
                WithIdenticalParagraphCounts.new(
                  structural_similarity, primary_sequence, foreign_sequence
                )
              }

              describe '#align' do

                it 'handles default data' do
                  with_identical_paragraph_counts.align.result.map{ |bilingual_paragraph_pair|
                    bilingual_paragraph_pair.aligned_text_pairs.map { |btp|
                      [btp.primary_contents, btp.foreign_contents]
                    }
                  }.must_equal([[[primary_contents, foreign_contents]]])
                end

              end

            end

          end
        end
      end
    end
  end
end
