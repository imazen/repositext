require_relative '../../../../helper'

class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        describe ComputeOperations do

          let(:default_computer){
            SubtitleOperationsForFile.new(
              '_content_at_file_to',
              '_repo_base_dir',
              {}
            )
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
          let(:default_operations){
            [
              ::Repositext::Subtitle::Operation::Merge.new(
                operationId: 2,
                operationType: :merge,
                affectedStids: [
                  ::Repositext::Subtitle.new(persistent_id: "1000001"),
                  ::Repositext::Subtitle.new(persistent_id: "1000002"),
                ],
              ),
              ::Repositext::Subtitle::Operation::MoveLeft.new(
                operationId: 3,
                operationType: :moveLeft,
                affectedStids: [
                  ::Repositext::Subtitle.new(persistent_id: "1000002"),
                  ::Repositext::Subtitle.new(persistent_id: "1000003"),
                ],
              ),
              ::Repositext::Subtitle::Operation::Insert.new(
                operationId: 4,
                operationType: :insert,
                afterStid: "1000003",
                affectedStids: [
                  ::Repositext::Subtitle.new(persistent_id: "tmp-1000003+1"),
                ],
              ),
            ]
          }

          describe '#compute_operations' do
            it "Handles default data" do
              default_computer.send(
                :compute_operations,
                default_operation_subtitle_pair_groups,
              ).must_equal(default_operations)
            end
          end
        end
      end
    end
  end
end
