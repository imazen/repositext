require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        describe OperationsExtractor do

          describe '#compute_string_overlap' do
            let(:operations_extractor){
              OperationsExtractor.new([], '')
            }
            [
              [
                "Empty string",
                "asdf",
                "",
                0
              ],
              [
                "14 char identical overlap",
                "abcd efgh ijkl mnop common overlap",
                                    "common overlap ponm lkji hgfe dcba",
                11
              ],
              [
                "14 char similar overlap",
                "abcd efgh ijkl mnop comXon overlap",
                                    "common overlap ponm lkji hgfe dcba",
                12
              ],
              [
                "No overlap",
                "abcd efgh ijkl mnop",
                                    "ponm lkji hgfe dcba",
                0
              ],
              [
                "4 char identical overlap",
                "abcd efgh ijkl mnop comm",
                                    "comm ponm lkji hgfe dcba",
                4
              ],
              [
                "Min overlap for medium repetition",
                "abcd efgh ijkl mnop comm comm comm",
                                              "comm comm ponm lkji hgfe dcba",
                4
              ],
              [
                "Min overlap for short repetition",
                "abcd efgh ijkl mnop in in",
                                    "in in ponm lkji hgfe dcba",
                5
              ],
              [
                "55-0815 (a)",
                "healing campaign and if you re you re still here there",
                                   "and if you re live near there we ll be looking forward to s",
                29
              ],
              [
                "55-0815 (b)",
                "every believer. Well, then… Thank you.",
                                 "Well, that’s perfect. If God has",
                0
              ],
              [
                "55-0815 (c)",
                "judgment and condemn many scholars, and teachers, and priests today.",
                                                    "and preachers, and priests today. She recognized it.",
                25
              ],

            ].each do |desc, string_a, string_b, xpect|
              it "Handles #{ desc }" do
                operations_extractor.send(
                  :compute_string_overlap,
                  string_a,
                  string_b,
                  3,
                  false # set to true for debug output
                ).must_equal(xpect)
              end
            end
          end

          describe '#sufficient_overlap_similarity?' do
            let(:operations_extractor){
              OperationsExtractor.new([], '')
            }
            [
              ["Overlap 0", 1.0, 0, false],
              ["Overlap 1", 1.0, 1, false],
              ["Overlap 2", 1.0, 2, false],
              ["Overlap 3, low sim", 0.8, 3, false],
              ["Overlap 3, high sim", 1.0, 3, true],
              ["Overlap 4, low sim", 0.8, 4, false],
              ["Overlap 4, high sim", 1.0, 4, true],
              ["Overlap 5, low sim", 0.7, 5, false],
              ["Overlap 5, high sim", 0.8, 5, true],
              ["Overlap 8, low sim", 0.7, 8, false],
              ["Overlap 8, high sim", 0.8, 8, true],
              ["Overlap 9, low sim", 0.7, 9, false],
              ["Overlap 9, high sim", 0.75, 9, true],
              ["Overlap 10, low sim", 0.7, 10, false],
              ["Overlap 10, high sim", 0.75, 10, true],
              ["Overlap 11, low sim", 0.7, 11, false],
              ["Overlap 11, high sim", 0.71, 11, true],
              ["Overlap 20, low sim", 0.7, 20, false],
              ["Overlap 20, high sim", 0.71, 20, true],
              ["Overlap 21, low sim", 0.65, 21, false],
              ["Overlap 21, high sim", 0.66, 21, true],
            ].each do |desc, sim, overlap, xpect|
              it "Handles #{ desc }" do
                operations_extractor.send(
                  :sufficient_overlap_similarity?,
                  sim,
                  overlap
                ).must_equal(xpect)
              end
            end
          end
        end
      end
    end
  end
end
