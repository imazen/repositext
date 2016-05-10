# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class RFile
    describe 'HasCorrespondingDataJsonFile' do
      let(:contents) { '{}' }
      let(:language) { Language::English.new }
      let(:filename) { '/repositext/ct-general/content/57/eng0103-1234.at' }
      let(:default_rfile) { RFile::ContentAt.new(contents, language, filename) }

      describe '#corresponding_data_json_file' do
        # TODO
      end

      describe '#corresponding_data_json_filename' do
        it 'computes default filename' do
          default_rfile.corresponding_data_json_filename.must_equal(
            '/repositext/ct-general/content/57/eng0103-1234.data.json'
          )
        end
      end

      describe '#read_file_level_data' do
        # TODO
      end

      describe '#update_file_level_data' do
        # TODO
      end
    end
  end
end
