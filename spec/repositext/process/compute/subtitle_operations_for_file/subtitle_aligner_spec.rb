require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        describe SubtitleAligner do
          describe '#get_optimal_alignment' do
            [
              [
                'Identical sequences',
                [
                  { content: "word1 word2 word3" },
                  { content: "word4 word5 word6" },
                ],
                [
                  { content: "word1 word2 word3" },
                  { content: "word4 word5 word6" },
                ],
                [
                  [
                    { content: "word1 word2 word3" },
                    { content: "word4 word5 word6" },
                  ],
                  [
                    { content: "word1 word2 word3" },
                    { content: "word4 word5 word6" },
                  ],
                ],
              ],
              [
                "tbd",
                [
                  { content: "word1 word2 word3" },
                  { content: "word4 word5 word6 word7 word8 word9 word10 word11 word12" },
                ],
                [
                  { content: "word1 word2 word3" },
                  { content: "word4 word5 word6" },
                  { content: "word7 word8 word9 word10 word11 word12" },
                ],
                [
                  [
                    { content: "word1 word2 word3" },
                    { content: "word4 word5 word6 word7 word8 word9 word10 word11 word12" },
                    { content: "", subtitle_count: 0 },
                  ],
                  [
                    { content: "word1 word2 word3" },
                    { content: "word4 word5 word6" },
                    { content: "word7 word8 word9 word10 word11 word12" },
                  ],
                ],
              ],
            ].each do |desc, sts_from, sts_to, xpect|
              it "Handles #{ desc }" do
                aligner = SubtitleAligner.new(
                  sts_from,
                  sts_to,
                  diagonal_band_range: 100
                )
                aligner.get_optimal_alignment.must_equal(xpect)
              end
            end
          end

          # describe '#compute_score' do
          #   it "Handles #{ a }, #{ b }" do
          #     aligner = SubtitleAligner.new(sts_from, sts_to)
          #     aligned_subtitles_from, aligned_subtitles_to = aligner.get_optimal_alignment

          #     JaccardSimilarityComputer.compute(
          #       a.join(' '),
          #       b.join(' '),
          #       attrs[:truncate_to_shortest],
          #       attrs[:alignment]
          #     ).must_equal(xpect)
          #   end
          # end

          describe 'diagonal_band_range' do

            let(:base_sequence){
              base_sequence = [
                {content: 'ABCD'}, {content: 'EFGH'}, {content: 'IJKL'}
              ]
            }
            let(:repeating_sequence){ base_sequence * 3 }

            it "Computes all scores if large" do
              aligner = SubtitleAligner.new(
                repeating_sequence,
                repeating_sequence,
                diagonal_band_range: 100
              )
              trb_mtrx = aligner.inspect_matrix(:traceback)
              trb_mtrx.must_equal([
                %(left_seq = {:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}),
                %(top_seq = {:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}),
                %(),
                %(      {:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}),
                %(     x  ←  ←  ←  ←  ←  ←  ←  ←  ←),
                %({:content=>"ABCD"}  ↑  ⬉  ←  ←  ⬉  ←  ←  ⬉  ←  ←),
                %({:content=>"EFGH"}  ↑  ↑  ⬉  ←  ←  ⬉  ←  ←  ⬉  ←),
                %({:content=>"IJKL"}  ↑  ↑  ↑  ⬉  ←  ←  ⬉  ←  ←  ⬉),
                %({:content=>"ABCD"}  ↑  ⬉  ↑  ↑  ⬉  ←  ←  ⬉  ←  ←),
                %({:content=>"EFGH"}  ↑  ↑  ⬉  ↑  ↑  ⬉  ←  ←  ⬉  ←),
                %({:content=>"IJKL"}  ↑  ↑  ↑  ⬉  ↑  ↑  ⬉  ←  ←  ⬉),
                %({:content=>"ABCD"}  ↑  ⬉  ↑  ↑  ⬉  ↑  ↑  ⬉  ←  ←),
                %({:content=>"EFGH"}  ↑  ↑  ⬉  ↑  ↑  ⬉  ↑  ↑  ⬉  ←),
                %({:content=>"IJKL"}  ↑  ↑  ↑  ⬉  ↑  ↑  ⬉  ↑  ↑  ⬉),
                "",
              ].join("\n"))
            end

            it "Computes scores around diagonal if small" do
              aligner = SubtitleAligner.new(
                repeating_sequence,
                repeating_sequence,
                diagonal_band_range: 2
              )
              trb_mtrx = aligner.inspect_matrix(:traceback)
              trb_mtrx.must_equal([
                %(left_seq = {:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}),
                %(top_seq = {:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}),
                %(),
                %(      {:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}{:content=>"ABCD"}{:content=>"EFGH"}{:content=>"IJKL"}),
                %(     x  ←  ←  ←  ←  ←  ←  ←  ←  ←),
                %({:content=>"ABCD"}  ↑  ⬉  ←  ←  ←  ←  ←  ←  ←  ←),
                %({:content=>"EFGH"}  ↑  ↑  ⬉  ←  ←  ←  ←  ←  ←  ←),
                %({:content=>"IJKL"}  ↑  ↑  ↑  ⬉  ←  ←  ←  ←  ←  ←),
                %({:content=>"ABCD"}  ↑  ↑  ↑  ↑  ⬉  ←  ←  ←  ←  ←),
                %({:content=>"EFGH"}  ↑  ↑  ↑  ↑  ↑  ⬉  ←  ←  ←  ←),
                %({:content=>"IJKL"}  ↑  ↑  ↑  ↑  ↑  ↑  ⬉  ←  ←  ←),
                %({:content=>"ABCD"}  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ⬉  ←  ←),
                %({:content=>"EFGH"}  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ⬉  ←),
                %({:content=>"IJKL"}  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ⬉),
                "",
              ].join("\n"))
            end

          end
        end
      end
    end
  end
end

