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
                [0.5833333333333334, 1.0],
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
                [0.2857142857142857, 0.9333333333333333],
              ],
              [
                %(ijkl mnop qrst),
                %(abcd efgh ijkl mnop qrst),
                { truncate_to_shortest: 100_000, alignment: :left },
                [0.2857142857142857, 0.9333333333333333],
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
                [0.6666666666666666, 0.2],
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
                "asdf sdfg qwer [poi",
                "",
                0
              ],
              [
                "16 char identical overlap",
                "abcd efgh ijkl mnop common 12 overlap",
                                    "common 12 overlap ponm lkji hgfe dcba",
                13
              ],
              [
                "16 char similar overlap",
                "abcd efgh ijkl mnop comXon 12 overlap",
                                    "common 12 overlap ponm lkji hgfe dcba",
                13
              ],
              [
                "No overlap",
                "abcd efgh ijkl mnop",
                                    "ponm lkji hgfe dcba",
                0
              ],
              [
                "Min overlap for medium repetition",
                "abcd efgh ijkl mnop comm comm comm comm",
                                                   "comm comm comm ponm lkji hgfe dcba",
                4
              ],
              [
                "Min overlap for short repetition",
                "abcd efgh ijkl mnop i i",
                                    "i i ponm lkji hgfe dcba",
                3
              ],
              [
                "Shorter string one less than min_overlap of 2",
                "overlap",
                      "p",
                0
              ],
              [
                "Shorter string is exactly min_overlap of 3",
                "overlap",
                    "lap",
                3
              ],
              [
                "Shorter string is one more than min_overlap of 3",
                "overlap",
                   "rlap",
                4
              ],
              [
                "test case",
                "something i didn t want… no",
                                         "no it was just something that",
                2
              ],
            ].each do |desc, string_a, string_b, xpect|
              it "Handles #{ desc }" do
                StringComputations.overlap(
                  string_a,
                  string_b,
                  0.67,
                  false # set to true for debug output
                ).must_equal(xpect)
              end
            end
          end

          describe '#sufficient_overlap_similarity?' do
            [
              ["Overlap 0", 1.0, 0, false],
              ["Overlap 1", 1.0, 1, false],
              ["Overlap 2, low sim", 0.8, 2, false],
              ["Overlap 2, high sim", 1.0, 2, true],
              ["Overlap 3, low sim", 0.8, 3, false],
              ["Overlap 3, high sim", 1.0, 3, true],
              ["Overlap 4, low sim", 0.8, 4, false],
              ["Overlap 4, high sim", 1.0, 4, true],
              ["Overlap 5, low sim", 0.6, 5, false],
              ["Overlap 5, high sim", 1.0, 5, true],
              ["Overlap 10, low sim", 0.6, 10, false],
              ["Overlap 10, high sim", 0.7, 10, true],
            ].each do |desc, sim, overlap, xpect|
              it "Handles #{ desc }" do
                StringComputations.sufficient_overlap_similarity?(
                  sim,
                  overlap,
                  0.7
                ).must_equal(xpect)
              end
            end
          end

        end
      end
    end
  end
end
