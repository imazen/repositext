require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile

        describe StringComputations do

          describe '.similarity' do

            [
              [
                %(identical strings abcd efgh ijkl mnop qrst uvwx yz12 3456 7890),
                %(identical strings abcd efgh ijkl mnop qrst uvwx yz12 3456 7890),
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
              [
                %(same tokens different order abcd efgh ijkl mnop qrst uvwx yz12 3456 7890),
                %(same tokens different order efgh abcd ijkl mnop qrst uvwx yz12 3456 7890),
                { truncate_to_shortest: 100_000, alignment: :left },
                [0.9305555555555556, 1.0],
              ],
              [
                %(abcd efgh ijkl),
                %(abcd efgh ijkl mnop qrst),
                { truncate_to_shortest: false, alignment: :left },
                [0.5833333333333334, 0.8],
              ],
              [
                %(abcd efgh ijkl),
                %(abcd efgh ijkl mnop qrst),
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
              [
                          %(abcd efgh ijkl),
                %(abcd efgh ijkl mnop qrst),
                { truncate_to_shortest: 100_000, alignment: :right },
                [0.2857142857142857, 0.4666666666666667],
              ],
              [
                %(ijkl mnop qrst),
                %(abcd efgh ijkl mnop qrst),
                { truncate_to_shortest: 100_000, alignment: :left },
                [0.2857142857142857, 0.4666666666666667],
              ],
              [
                          %(ijkl mnop qrst),
                %(abcd efgh ijkl mnop qrst),
                { truncate_to_shortest: 100_000, alignment: :right },
                [1.0, 1.0],
              ],
              [
                          %(ijkl mnop qrst),
                %(abcd efgh ijkl mnop qrst),
                { truncate_to_shortest: 100_000, alignment: :right },
                [1.0, 1.0],
              ],
              [
                %(one string has duplicate token abcd efgh ijkl mnop qrst uvwx uvwx),
                %(one string has duplicate token abcd efgh ijkl mnop qrst uvwx),
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
              [
                                    " %It’s almost like the comedian said the other night, ",
                "@look at everything. %It’s almost like the comedian said the other night, ",
                { truncate_to_shortest: 100_000, alignment: :right },
                [1.0, 1.0],
              ],
              [
                'one empty string',
                '',
                {  },
                [0.0, 0.0],
              ],
              [
                ' in',
                'in ',
                {  },
                [0.6666666666666666, 0.1],
              ],
            ].each do |(a, b, attrs, xpect)|
              it "Handles #{ a }, #{ b }" do
                StringComputations.similarity(
                  a,
                  b,
                  attrs[:truncate_to_shortest],
                  attrs[:alignment]
                ).must_equal(xpect)
              end
            end
          end

          describe '.repetitions' do
            [
              [
                "here we go repetition number one repetition number two repetition number three and then some more",
                { " repetition number " => [10, 32, 54] }
              ],
              [
                "this string does not contain any repetitions whatsoever",
                {}
              ],
              [
                "this string contains two long enough repetitions long enough repetitions",
                { " long enough repetitions"=>[24, 48] }
              ],
              [
                "repetitions are too short short",
                {}
              ],
              [
                "long enough repetition long enough repetition at the beginning and end long enough repetition",
                { "long enough repetition"=>[0, 23, 71] }
              ],
            ].each do |test_string, xpect|
              it "Handles #{ test_string }" do
                StringComputations.repetitions(
                  test_string
                ).must_equal(xpect)
              end
            end
          end

          describe '.overlap' do
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
                StringComputations.overlap(
                  string_a,
                  string_b,
                  3,
                  false # set to true for debug output
                ).must_equal(xpect)
              end
            end
          end

          describe '#sufficient_overlap_similarity?' do
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
                StringComputations.sufficient_overlap_similarity?(
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
