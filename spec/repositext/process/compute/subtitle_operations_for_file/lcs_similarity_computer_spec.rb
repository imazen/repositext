require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile

        describe LcsSimilarityComputer do

          describe '.compute' do

            [
              [
                %w[identical strings abcd efgh ijkl mnop qrst uvwx yz12 3456 7890],
                %w[identical strings abcd efgh ijkl mnop qrst uvwx yz12 3456 7890],
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
              [
                %w[same tokens different order abcd efgh ijkl mnop qrst uvwx yz12 3456 7890],
                %w[same tokens different order efgh abcd ijkl mnop qrst uvwx yz12 3456 7890],
                { truncate_to_shortest: 100_000, alignment: :left },
                [0.9305555555555556, 1.0],
              ],
              [
                %w[abcd efgh ijkl            ],
                %w[abcd efgh ijkl mnop qrst],
                { truncate_to_shortest: false, alignment: :left },
                [0.5833333333333334, 0.48],
              ],
              [
                %w[abcd efgh ijkl],
                %w[abcd efgh ijkl mnop qrst],
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
              [
                            %w[abcd efgh ijkl],
                %w[abcd efgh ijkl mnop qrst],
                { truncate_to_shortest: 100_000, alignment: :right },
                [0.2857142857142857, 0.5833333333333334],
              ],
              [
                %w[ijkl mnop qrst],
                %w[abcd efgh ijkl mnop qrst],
                { truncate_to_shortest: 100_000, alignment: :left },
                [0.2857142857142857, 0.5833333333333334],
              ],
              [
                            %w[ijkl mnop qrst],
                %w[abcd efgh ijkl mnop qrst],
                { truncate_to_shortest: 100_000, alignment: :right },
                [1.0, 1.0],
              ],
              [
                            %w[ijkl mnop qrst],
                %w[abcd efgh ijkl mnop qrst],
                { truncate_to_shortest: 100_000, alignment: :right },
                [1.0, 1.0],
              ],
              [
                %w[one string has duplicate token abcd efgh ijkl mnop qrst uvwx uvwx],
                %w[one string has duplicate token abcd efgh ijkl mnop qrst uvwx],
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
            ].each do |(a, b, attrs, xpect)|
              it "Handles #{ a }, #{ b }" do
                LcsSimilarityComputer.compute(
                  a.join(' '),
                  b.join(' '),
                  attrs[:truncate_to_shortest],
                  attrs[:alignment]
                ).must_equal(xpect)
              end
            end

            [
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
            ].each do |(a, b, attrs, xpect)|
              it "Handles #{ a }, #{ b }" do
                LcsSimilarityComputer.compute(
                  a,
                  b,
                  attrs[:truncate_to_shortest],
                  attrs[:alignment]
                ).must_equal(xpect)
              end
            end

          end

        end

      end
    end
  end
end
