# encoding UTF-8
require_relative '../../../../../../../helper'

class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair
          class ParagraphsAligner
            class WithDifferentParagraphCounts

              describe NwAligner do

                describe '#get_optimal_alignment' do

                  [
                    [
                      'Perfect alignment of 3 paragraphs',
                      [
                        { type: :p, key: 1, contents: 'word1' },
                        { type: :p, key: 2, contents: 'word2' },
                        { type: :p, key: 3, contents: 'word3' },
                      ],
                      [
                        { type: :p, key: 1, contents: 'palabra1' },
                        { type: :p, key: 2, contents: 'palabra2' },
                        { type: :p, key: 3, contents: 'palabra3' },
                      ],
                      [
                        [
                          [:p, "word1"],
                          [:p, "word2"],
                          [:p, "word3"],
                        ],
                        [
                          [:p, "palabra1"],
                          [:p, "palabra2"],
                          [:p, "palabra3"],
                        ]
                      ]
                    ],
                  ].each { |(description, primary_be_attrs, foreign_be_attrs, xpect)|
                    it "handles #{ description }" do
                      primary_block_elements = primary_be_attrs.map { |e|
                        Kramdown::Converter::ParagraphAlignmentObjects::BlockElement.new(e)
                      }
                      foreign_block_elements = foreign_be_attrs.map { |e|
                        Kramdown::Converter::ParagraphAlignmentObjects::BlockElement.new(e)
                      }
                      t = NwAligner.new(
                        primary_block_elements,
                        foreign_block_elements
                      ).get_optimal_alignment
                      t.map { |block_elements_list|
                        block_elements_list.map { |block_element|
                          [block_element.type, block_element.contents]
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
end
