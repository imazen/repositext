require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        describe ExtractOperationSubtitlePairGroups do

          let(:default_computer){
            SubtitleOperationsForFile.new(
              '_content_at_file_to',
              '_repo_base_dir',
              {}
            )
          }
          let(:default_aligned_subtitle_pairs){
            [
              {
                :content_length_change=>24,
                :first_in_para=>true,
                :index=>1,
                :last_in_para=>nil,
                :sim_abs=>[0.5555555555555556, 0.5],
                :sim_left=>[1.0, 1.0],
                :sim_right=>[0.1111111111111111, 0.5],
                :subtitle_count_change=>0,
                :subtitle_object => ::Repositext::Subtitle.new(
                  persistent_id: "1000001",
                  tmp_attrs: { :before=>"word1 word2 word3 word4 word5", :after=>"word1 word2 word3 word4 word5 word6 word7 word8 word9" }
                ),
                :type=>:left_aligned,
                from: {
                  content: "word1 word2 word3 word4 word5",
                  persistent_id: "1000001",
                  subtitle_count: 1,
                },
                to: {
                  content: "word1 word2 word3 word4 word5 word6 word7 word8 word9",
                  persistent_id: nil,
                  first_in_para: true,
                  subtitle_count: 1,
                },
              }, {
                :content_length_change=>-30,
                :first_in_para=>nil,
                :index=>2,
                :last_in_para=>nil,
                :sim_abs=>[0.0, 0.0],
                :sim_left=>[0.0, 0.0],
                :sim_right=>[0.0, 0.0],
                :subtitle_count_change=>-1,
                :subtitle_object => ::Repositext::Subtitle.new(
                  persistent_id: "1000002",
                  tmp_attrs: { :before=>"word6 word7 word8 word9 word10", :after=>"" }
                ),
                :type=>:st_removed,
                from: {
                  content: "word6 word7 word8 word9 word10",
                  persistent_id: "1000002",
                  subtitle_count: 1,
                },
                to: {
                  content: "",
                  subtitle_count: 0,
                },
              }, {
                :content_length_change=>7,
                :first_in_para=>nil,
                :index=>3,
                :last_in_para=>nil,
                :sim_abs=>[0.9090909090909091, 1.0],
                :sim_left=>[0.6666666666666666, 0.5],
                :sim_right=>[1.0, 1.0],
                :subtitle_count_change=>0,
                :subtitle_object => ::Repositext::Subtitle.new(
                  persistent_id: "1000003",
                  tmp_attrs: { :before=>"word11 word12 word13 word14 word15 word16 word17 word18 word19 word20", :after=>"word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20" }
                ),
                :type=>:right_aligned,
                from: {
                  content: "word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
                  persistent_id: "1000003",
                  subtitle_count: 1,
                },
                to: {
                  content: "word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20",
                  persistent_id: nil,
                  subtitle_count: 1,
                },
              }, {
                :content_length_change=>27,
                :first_in_para=>nil,
                :index=>4,
                :last_in_para=>true,
                :sim_abs=>[0.0, 0.0],
                :sim_left=>[0.0, 0.0],
                :sim_right=>[0.0, 0.0],
                :subtitle_count_change=>1,
                :subtitle_object =>  ::Repositext::Subtitle.new(
                  persistent_id: "tmp-1000003+1",
                  tmp_attrs: { :before=>"", :after=>"word20 word21 word22 word23" }
                ),
                :type=>:st_added,
                from: {
                  content: "",
                  subtitle_count: 0,
                },
                to: {
                  content: "word20 word21 word22 word23",
                  persistent_id: nil,
                  last_in_para: true,
                  subtitle_count: 1,
                },
              }
            ]
          }
          let(:default_operation_subtitle_pair_groups){
            [
              [
                {
                  :content_length_change=>24,
                  :first_in_para=>true,
                  :index=>1,
                  :last_in_para=>nil,
                  :sim_abs=>[0.5555555555555556, 0.5],
                  :sim_left=>[1.0, 1.0],
                  :sim_right=>[0.1111111111111111, 0.5],
                  :subtitle_count_change=>0,
                  :subtitle_object => ::Repositext::Subtitle.new(persistent_id: "1000001"),
                  :type=>:left_aligned,
                  :from=>{:content=>"word1 word2 word3 word4 word5", :persistent_id=>"1000001", :subtitle_count=>1},
                  :to=>{:content=>"word1 word2 word3 word4 word5 word6 word7 word8 word9", :persistent_id=>nil, :first_in_para=>true, :subtitle_count=>1},
                }, {
                  :content_length_change=>-30,
                  :first_in_para=>nil,
                  :index=>2,
                  :last_in_para=>nil,
                  :sim_abs=>[0.0, 0.0],
                  :sim_left=>[0.0, 0.0],
                  :sim_right=>[0.0, 0.0],
                  :subtitle_count_change=>-1,
                  :subtitle_object => ::Repositext::Subtitle.new(persistent_id: "1000002"),
                  :type=>:st_removed,
                  :from=>{:content=>"word6 word7 word8 word9 word10", :persistent_id=>"1000002", :subtitle_count=>1},
                  :to=>{:content=>"", :subtitle_count=>0},
                }, {
                  :content_length_change=>7,
                  :first_in_para=>nil,
                  :index=>3,
                  :last_in_para=>nil,
                  :sim_abs=>[0.9090909090909091, 1.0],
                  :sim_left=>[0.6666666666666666, 0.5],
                  :sim_right=>[1.0, 1.0],
                  :subtitle_count_change=>0,
                  :subtitle_object => ::Repositext::Subtitle.new(persistent_id: "1000003"),
                  :type=>:right_aligned,
                  :from=>{:content=>"word11 word12 word13 word14 word15 word16 word17 word18 word19 word20", :persistent_id=>"1000003", :subtitle_count=>1},
                  :to=>{:content=>"word10 word11 word12 word13 word14 word15 word16 word17 word18 word19 word20", :persistent_id=>nil, :subtitle_count=>1},
                }
              ], [
                {
                  :content_length_change=>27,
                  :first_in_para=>nil,
                  :index=>4,
                  :last_in_para=>true,
                  :sim_abs=>[0.0, 0.0],
                  :sim_left=>[0.0, 0.0],
                  :sim_right=>[0.0, 0.0],
                  :subtitle_count_change=>1,
                  :subtitle_object => ::Repositext::Subtitle.new(persistent_id: "tmp-1000003+1"),
                  :type=>:st_added,
                  :from=>{:content=>"", :subtitle_count=>0},
                  :to=>{:content=>"word20 word21 word22 word23", :persistent_id=>nil, :last_in_para=>true, :subtitle_count=>1}
                }
              ]
            ]
          }

          describe '#extract_operation_subtitle_pair_groups' do
            it "Handles default data" do
              default_computer.send(
                :extract_operation_subtitle_pair_groups,
                default_aligned_subtitle_pairs,
              ).must_equal(default_operation_subtitle_pair_groups)
            end

            [
              [
                "All identical",
                [{ type: :identical }, { type: :identical }, { type: :identical }],
                []
              ],
              [
                "One left_aligned",
                [{ type: :identical }, { type: :left_aligned }, { type: :identical }],
                [[:left_aligned]]
              ],
              [
                "One right_aligned",
                [{ type: :identical }, { type: :right_aligned }, { type: :identical }],
                [[:right_aligned]]
              ],
              [
                "One unaligned",
                [{ type: :identical }, { type: :unaligned }, { type: :identical }],
                [[:unaligned]]
              ],
              [
                "One st_added",
                [{ type: :identical }, { type: :st_added }, { type: :identical }],
                [[:st_added]]
              ],
              [
                "One st_removed",
                [{ type: :identical }, { type: :st_removed }, { type: :identical }],
                [[:st_removed]]
              ],
# TODO: test the encountered patterns
            ].each { |desc, asps, xpect|
              it "Handles #{ desc }" do
                default_computer.send(
                  :extract_operation_subtitle_pair_groups,
                  asps,
                ).map { |group| group.map { |asp| asp[:type] } }.must_equal(xpect)
              end
            }
          end
        end
      end
    end
  end
end
