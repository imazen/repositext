require_relative '../../../helper'

class Repositext
  class Cli
    class Config
      describe FromJsonDataFile do

        let(:from_json_data_file) { FromJsonDataFile.new('_') }

        describe '#load' do
          it "loads a valid JSON string" do
            from_json_data_file.load(
              %({"settings": {"test_setting": "test_val"}})
            ).must_equal({ "test_setting"=>"test_val" })
          end
        end

      end
    end
  end
end
