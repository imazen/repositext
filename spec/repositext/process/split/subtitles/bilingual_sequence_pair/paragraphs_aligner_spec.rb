# encoding UTF-8
require_relative '../../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair

          describe ParagraphsAligner do

            let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
            let(:primary_contents) { 'word1 word2 word3' }
            let(:foreign_language) { Language::Spanish.new }
            let(:primary_language) { Language::English.new }
            let(:foreign_sequence) { Sequence.new(foreign_contents, foreign_language) }
            let(:primary_sequence) { Sequence.new(primary_contents, primary_language) }
            let(:paragraphs_aligner) { ParagraphsAligner.new(primary_sequence, foreign_sequence) }
            let(:structural_similarity) {
              {
                character_count_similarity: 0.5263157894736843,
                paragraph_count_similarity: 1.0,
                paragraph_numbers_similarity: 1.0,
                record_count_similarity: 1.0,
                record_ids_similarity: 1.0,
                subtitle_count_similarity: 1.0,
              }
            }

            describe '#align' do

              it 'handles default data' do
                paragraphs_aligner.align.result.map { |bilingual_paragraph_pair|
                  bilingual_paragraph_pair.aligned_text_pairs.map { |btp|
                    [btp.primary_contents, btp.foreign_contents]
                  }
                }.must_equal([[[primary_contents, foreign_contents]]])
              end

            end

            describe '#foreign_kramdown_doc' do

              it 'handles default data' do
                paragraphs_aligner.foreign_kramdown_doc.root.inspect_tree.must_equal(
                  %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}
                       - :p - {:location=>1}
                         - :text - {:location=>1} - \"palabra1 palabra2 palabra3\"
                    ).gsub(/\n                    /, "\n")
                )
              end

            end

            describe '#primary_kramdown_doc' do

              it 'handles default data' do
                paragraphs_aligner.primary_kramdown_doc.root.inspect_tree.must_equal(
                  %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}
                       - :p - {:location=>1}
                         - :text - {:location=>1} - \"word1 word2 word3\"
                    ).gsub(/\n                    /, "\n")
                )
              end

            end

            describe '#structural_similarity' do

              it 'handles default data' do
                paragraphs_aligner.structural_similarity.must_equal(structural_similarity)
              end

            end

            describe '#pick_alignment_strategy' do

              it 'handles default data' do
                paragraphs_aligner.send(
                  :pick_alignment_strategy, structural_similarity
                ).must_equal(ParagraphsAligner::WithIdenticalParagraphCounts)
              end

            end

          end

        end
      end
    end
  end
end
