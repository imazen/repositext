# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class RFile
    describe 'HasCorrespondingDataJsonFile' do
      let(:default_rfile) { get_r_file }

      describe '#corresponding_data_json_file' do
        # TODO
      end

      describe '#corresponding_data_json_filename' do
        it 'computes default filename' do
          default_rfile.corresponding_data_json_filename.must_equal(
            '/path-to/rt-english/ct-general/content/57/eng57-0103_1234.data.json'
          )
        end
      end

      describe '#read_file_level_data' do
        # TODO
      end

      describe '#update_file_level_data!' do
        # TODO
      end
    end
  end
end
