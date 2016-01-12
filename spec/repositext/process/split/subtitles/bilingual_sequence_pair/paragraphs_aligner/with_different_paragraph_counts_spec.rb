# encoding UTF-8
require_relative '../../../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair
          class ParagraphsAligner

            describe WithDifferentParagraphCounts do

              let(:foreign_contents) { 'palabra1 palabra2 palabra3' }
              let(:primary_contents) { 'word1 word2 word3' }
              let(:foreign_language) { Language::Spanish.new }
              let(:primary_language) { Language::English.new }
              let(:foreign_sequence) { Sequence.new(foreign_contents, foreign_language) }
              let(:primary_sequence) { Sequence.new(primary_contents, primary_language) }
              let(:paragraphs_aligner) { ParagraphsAligner.new(primary_sequence, foreign_sequence) }
              let(:structural_similarity) { paragraphs_aligner.structural_similarity }
              let(:with_different_paragraph_counts) {
                WithDifferentParagraphCounts.new(
                  structural_similarity, primary_sequence, foreign_sequence
                )
              }

              describe '#align' do

                it 'handles default data' do
                  with_different_paragraph_counts.align.result.map{ |bilingual_paragraph_pair|
                    bilingual_paragraph_pair.aligned_text_pairs.map { |btp|
                      [btp.primary_contents, btp.foreign_contents]
                    }
                  }.must_equal([[[primary_contents, foreign_contents]]])
                end

                [
                  [
                    'with paragraph numbers, foreign paragraph missing at the beginning',
                    ["1 word1 word2", "2 word3 word4", "3 word5 word6"],
                    [                 "2 palabra3 palabra4", "3 palabra5 palabra6"],
                    [
                      [["1 word1 word2", ""]],
                      [["2 word3 word4", "2 palabra3 palabra4"]],
                      [["3 word5 word6", "3 palabra5 palabra6"]],
                    ]
                  ],
                  [
                    'with paragraph numbers, foreign paragraph missing in the middle',
                    ["1 word1 word2", "2 word3 word4", "3 word5 word6"],
                    ["1 palabra1 palabra2",          "3 palabra3 palabra4"],
                    [
                      [["1 word1 word2", "1 palabra1 palabra2"]],
                      [["2 word3 word4", ""]],
                      [["3 word5 word6", "3 palabra3 palabra4"]],
                    ]
                  ],
                  [
                    'with paragraph numbers, foreign paragraph missing at the end',
                    ["1 word1 word2", "2 word3 word4", "3 word5 word6"],
                    ["1 palabra1 palabra2", "2 palabra3 palabra4"],
                    [
                      [["1 word1 word2", "1 palabra1 palabra2"]],
                      [["2 word3 word4", "2 palabra3 palabra4"]],
                      [["3 word5 word6", ""]],
                    ]
                  ],
                ].each { |(description, primary_para_contents, foreign_para_contents, xpect)|
                  it "handles #{ description }" do
                    t = WithDifferentParagraphCounts.new(
                      { },
                      Sequence.new(primary_para_contents.join("\n\n"), primary_language),
                      Sequence.new(foreign_para_contents.join("\n\n"), foreign_language)
                    ).align.result
                    t.map{ |bilingual_paragraph_pair|
                      bilingual_paragraph_pair.aligned_text_pairs.map { |btp|
                        [btp.primary_contents, btp.foreign_contents]
                      }
                    }.must_equal(xpect)
                  end
                }

              end

            end

          end
        end
      end
    end
  end
end
