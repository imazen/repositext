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
                  { content_sim: "qwerf okjhb qwsza" },
                  { content_sim: "oiuyt ikjfb plwsr" },
                ],
                [
                  { content_sim: "qwerf okjhb qwsza" },
                  { content_sim: "oiuyt ikjfb plwsr" },
                ],
                [
                  [
                    { content_sim: "qwerf okjhb qwsza" },
                    { content_sim: "oiuyt ikjfb plwsr" },
                  ],
                  [
                    { content_sim: "qwerf okjhb qwsza" },
                    { content_sim: "oiuyt ikjfb plwsr" },
                  ],
                ],
              ],
              [
                "tbd",
                [
                  { content_sim: "qwerf okjhb qwsza" },
                  { content_sim: "oiuyt ikjfb plwsr ujkdf ew34j epasl asdfe ghrns iwjdk" },
                ],
                [
                  { content_sim: "qwerf okjhb qwsza" },
                  { content_sim: "oiuyt ikjfb plwsr" },
                  { content_sim: "ujkdf ew34j epasl asdfe ghrns iwjdk" },
                ],
                [
                  [
                    { content_sim: "qwerf okjhb qwsza" },
                    { content_sim: "oiuyt ikjfb plwsr ujkdf ew34j epasl asdfe ghrns iwjdk" },
                    { content_sim: "", content: "", subtitle_count: 0 },
                  ],
                  [
                    { content_sim: "qwerf okjhb qwsza" },
                    { content_sim: "oiuyt ikjfb plwsr" },
                    { content_sim: "ujkdf ew34j epasl asdfe ghrns iwjdk" },
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

          describe '#compute_score' do
            [
              [
                'identical',
                'asdf ghjk zxcv vbnm qwer tyui sdfg',
                'asdf ghjk zxcv vbnm qwer tyui sdfg',
                1,
                1,
                100.0
              ],
              [
                'one letter changed',
                'asdf ghjk zxcv  bnm qwer tyui sdfg',
                'asdf ghjk zxcv vbnm qwer tyui sdfg',
                1,
                1,
                97.05882352941177
              ],
              [
                'Outside of diagonal_band_range',
                'asdf ghjk zxcv vbnm qwer tyui sdfg',
                'asdf ghjk zxcv vbnm qwer tyui sdfg',
                1,
                100,
                -1000
              ],
              [
                'Left aligned sim is preferred over absolute sim',
                'asdf ghjk zxcv  bnm qwer tyui sdfg jwewef lkadfg sdkfjgh aaslkdfj asld',
                'asdf ghjk zxcv vbnm qwer tyui sdfg',
                1,
                1,
                97.05882352941177
              ],
              [
                'Penalize low similarity slightly worse than gap',
                'asdf pppp wewe lkad sdkf jkgb',
                'asdf ghjk zxcv vbnm qwer tyui',
                1,
                1,
                -11
              ],
            ].each { |desc, left_txt, right_txt, row_index, col_index, xpect|
              it "Handles #{ desc }" do
                aligner = SubtitleAligner.new(
                  [],
                  [],
                  diagonal_band_range: 10
                )
                aligner.compute_score(
                  { content_sim: left_txt },
                  { content_sim: right_txt },
                  row_index,
                  col_index
                ).must_equal(xpect)
              end
            }
          end

          describe 'diagonal_band_range' do

            let(:base_sequence){
              base_sequence = [
                {content_sim: 'ABCD'}, {content_sim: 'EFGH'}, {content_sim: 'IJKL'}
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
                %(left_seq = {:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}),
                %(top_seq = {:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}),
                %(),
                %(      {:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}),
                %(     x  ←  ←  ←  ←  ←  ←  ←  ←  ←),
                %({:content_sim=>"ABCD"}  ↑  ⬉  ←  ←  ⬉  ←  ←  ⬉  ←  ←),
                %({:content_sim=>"EFGH"}  ↑  ↑  ⬉  ←  ←  ⬉  ←  ←  ⬉  ←),
                %({:content_sim=>"IJKL"}  ↑  ↑  ↑  ⬉  ←  ←  ⬉  ←  ←  ⬉),
                %({:content_sim=>"ABCD"}  ↑  ⬉  ↑  ↑  ⬉  ←  ←  ⬉  ←  ←),
                %({:content_sim=>"EFGH"}  ↑  ↑  ⬉  ↑  ↑  ⬉  ←  ←  ⬉  ←),
                %({:content_sim=>"IJKL"}  ↑  ↑  ↑  ⬉  ↑  ↑  ⬉  ←  ←  ⬉),
                %({:content_sim=>"ABCD"}  ↑  ⬉  ↑  ↑  ⬉  ↑  ↑  ⬉  ←  ←),
                %({:content_sim=>"EFGH"}  ↑  ↑  ⬉  ↑  ↑  ⬉  ↑  ↑  ⬉  ←),
                %({:content_sim=>"IJKL"}  ↑  ↑  ↑  ⬉  ↑  ↑  ⬉  ↑  ↑  ⬉),
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
                %(left_seq = {:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}),
                %(top_seq = {:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}),
                %(),
                %(      {:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}{:content_sim=>"ABCD"}{:content_sim=>"EFGH"}{:content_sim=>"IJKL"}),
                %(     x  ←  ←  ←  ←  ←  ←  ←  ←  ←),
                %({:content_sim=>"ABCD"}  ↑  ⬉  ←  ←  ←  ←  ←  ←  ←  ←),
                %({:content_sim=>"EFGH"}  ↑  ↑  ⬉  ←  ←  ←  ←  ←  ←  ←),
                %({:content_sim=>"IJKL"}  ↑  ↑  ↑  ⬉  ←  ←  ←  ←  ←  ←),
                %({:content_sim=>"ABCD"}  ↑  ↑  ↑  ↑  ⬉  ←  ←  ←  ←  ←),
                %({:content_sim=>"EFGH"}  ↑  ↑  ↑  ↑  ↑  ⬉  ←  ←  ←  ←),
                %({:content_sim=>"IJKL"}  ↑  ↑  ↑  ↑  ↑  ↑  ⬉  ←  ←  ←),
                %({:content_sim=>"ABCD"}  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ⬉  ←  ←),
                %({:content_sim=>"EFGH"}  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ⬉  ←),
                %({:content_sim=>"IJKL"}  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ⬉),
                "",
              ].join("\n"))
            end

          end
        end
      end
    end
  end
end

