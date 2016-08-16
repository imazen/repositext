# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class Process
    class Sync

      describe Subtitles do

        let(:process_sync_subtitles){
          Subtitles.new({})
        }

        describe '#compute_from_commit_from_latest_st_ops_file' do
          [
            ['st-ops-00001-791a1d-to-eea8b4.json', '791a1d'],
            [nil, nil],
          ].each do |test_name, xpect|
            it "handles #{ test_name.inspect }" do
              process_sync_subtitles.send(
                :compute_from_commit_from_latest_st_ops_file,
                test_name
              ).must_equal(xpect)
            end
          end
        end
      end
    end
  end
end
