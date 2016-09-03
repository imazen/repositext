require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile

        describe JaccardSimilarityComputer do

          describe '.compute' do

            [
              [
                %w[identical strings word1 word2 word3 word4 word5 word6 word7 word8 word9 word10],
                %w[identical strings word1 word2 word3 word4 word5 word6 word7 word8 word9 word10],
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
              [
                %w[same tokens different order word1 word2 word3 word4 word5 word6 word7 word8 word9 word10],
                %w[same tokens different order word2 word1 word3 word4 word5 word6 word7 word8 word9 word10],
                { truncate_to_shortest: 100_000, alignment: :left },
                [0.99, 1.0],
              ],
              [
                %w[word1 word2 word3            ],
                %w[word1 word2 word3 word4 word5],
                { truncate_to_shortest: false, alignment: :left },
                [0.6, 0.3],
              ],
              [
                %w[word1 word2 word3],
                %w[word1 word2 word3 word4 word5],
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
              [
                            %w[word1 word2 word3],
                %w[word1 word2 word3 word4 word5],
                { truncate_to_shortest: 100_000, alignment: :right },
                [0.2, 0.3],
              ],
              [
                %w[word3 word4 word5],
                %w[word1 word2 word3 word4 word5],
                { truncate_to_shortest: 100_000, alignment: :left },
                [0.2, 0.3],
              ],
              [
                            %w[word3 word4 word5],
                %w[word1 word2 word3 word4 word5],
                { truncate_to_shortest: 100_000, alignment: :right },
                [1.0, 1.0],
              ],
              [
                            %w[word3 word4 word5],
                %w[word1 word2 word3 word4 word5],
                { truncate_to_shortest: 100_000, alignment: :right },
                [1.0, 1.0],
              ],
              [
                %w[one string has duplicate token word1 word2 word3 word4 word5 word6 word6],
                %w[one string has duplicate token word1 word2 word3 word4 word5 word6],
                { truncate_to_shortest: 100_000, alignment: :left },
                [1.0, 1.0],
              ],
            ].each do |(a, b, attrs, xpect)|
              it "Handles #{ a }, #{ b }" do
                JaccardSimilarityComputer.compute(
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
                JaccardSimilarityComputer.compute(
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
