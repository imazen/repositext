require_relative '../../helper'

class Repositext
  class RFile
    describe DataJson do
      let(:default_data) {
        {
          'data' => {
            'st_sync_required' => true,
          },
          'settings' => {
            'st_sync_active' => true,
          },
        }
      }
      let(:contents) {
        JSON.generate(default_data, DataJson.json_formatting_options) + "\n"
      }
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

      describe '#get_all_attributes' do
        it 'handles default case' do
          default_rfile.get_all_attributes.must_equal(
            default_data
          )
        end
      end

      describe '#json_formatting_options' do
        it 'handles default case' do
          DataJson.json_formatting_options[:indent].must_equal('  ')
        end
      end

      describe '#read_data' do
        it 'handles default case' do
          default_rfile.read_data.must_equal(
            {
              'st_sync_required' => true,
            }
          )
        end
      end

      describe '#read_settings' do
        it 'handles default case' do
          default_rfile.read_settings.must_equal(
            {
              'st_sync_active' => true,
            }
          )
        end
      end

      describe '#update_data' do
        it 'adds a key under data' do
          JSON.load(
            default_rfile.update_data(
              'test_key' => 'test val'
            )
          ).must_equal(
            {
              'data' => {
                'st_sync_required' => true,
                'test_key' => 'test val',
              },
              'settings' => {
                'st_sync_active' => true,
              },
            }
          )
        end

        it 'updates a key under data' do
          JSON.load(
            default_rfile.update_data(
              'st_sync_required' => false
            )
          ).must_equal(
            {
              'data' => {
                'st_sync_required' => false,
              },
              'settings' => {
                'st_sync_active' => true,
              },
            }
          )
        end
      end

      describe '#update_data!' do
        # TODO
      end

      describe '#update_settings' do
        it 'adds a key under settings' do
          JSON.load(
            default_rfile.update_settings(
              'test_key' => 'test val'
            )
          ).must_equal(
            {
              'data' => {
                'st_sync_required' => true,
              },
              'settings' => {
                'st_sync_active' => true,
                'test_key' => 'test val',
              },
            }
          )
        end

        it 'updates a key under settings' do
          JSON.load(
            default_rfile.update_settings(
              'st_sync_active' => false
            )
          ).must_equal(
            {
              'data' => {
                'st_sync_required' => true,
              },
              'settings' => {
                'st_sync_active' => false,
              },
            }
          )
        end
      end

      describe '#update_settings!' do
        # TODO
      end

    end
  end
end
