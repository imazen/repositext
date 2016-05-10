require_relative '../../helper'

class Repositext
  class RFile
    describe DataJson do
      let(:contents) { %({ "data": {}, "settings": {}, "subtitles": {} }) }
      let(:language) { Language::English.new }
      let(:filename) { '/content/57/eng0103-1234.data.json' }
      let(:default_rfile) { RFile::DataJson.new(contents, language, filename) }

      describe '.create_empty_data_json_file!' do
        # TODO
      end

      describe '.default_file_contents' do
        it 'handles default case' do
          DataJson.default_file_contents.index('data').must_equal(5)
        end
      end

      describe '.default_data' do
        it 'handles default case' do
          DataJson.default_data['data'].must_equal({})
        end
      end

      describe '.json_formatting_options' do
        it 'handles default case' do
          DataJson.json_formatting_options[:indent].must_equal('  ')
        end
      end

      describe '#get_file_level_data' do
        it 'handles default case' do
          default_rfile.get_file_level_data.must_equal(
            {"data"=>{}, "settings"=>{}, "subtitles"=>{}}
          )
        end
      end

      describe '#json_formatting_options' do
        it 'handles default case' do
          DataJson.json_formatting_options[:indent].must_equal('  ')
        end
      end

      describe '#update_file_level_data' do
        # TODO
      end
    end
  end
end
