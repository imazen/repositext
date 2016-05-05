require_relative '../../helper'

class Repositext
  class Cli
    describe Config do

      describe 'BASE_DIR_NAME_REGEX' do
        [
          ['content_dir', true],
          ['some_dir', true],
          ['wont_match', false],
          ['contents', false],
          ['/dir1/some_dir', false],
          ['/some/dir', false],
        ].each do |(test_string, xpect)|
          it "Handles #{ test_string.inspect }" do
            (!!(test_string =~ Config::BASE_DIR_NAME_REGEX)).must_equal(xpect)
          end
        end
      end

      describe 'FILE_EXTENSION_NAME_REGEX' do
        [
          ['at_extension', true],
          ['.at', false],
          ['*.some_file', false],
          ['', false],
          ['.{at,json,md,txt}', false],
        ].each do |(test_string, xpect)|
          it "Handles #{ test_string.inspect }" do
            (!!(test_string =~ Config::FILE_EXTENSION_NAME_REGEX)).must_equal(xpect)
          end
        end
      end

      describe 'FILE_SELECTOR_NAME_REGEX' do
        [
          ['all_files', true],
          ['validation_report_file', true],
          ['**/*', false],
          ['**/*{65-0418m,63-0418e}_*', false],
        ].each do |(test_string, xpect)|
          it "Handles #{ test_string.inspect }" do
            (!!(test_string =~ Config::FILE_SELECTOR_NAME_REGEX)).must_equal(xpect)
          end
        end
      end

      let(:valid_settings){
        {
          "settings" => {
            "base_dir_test_dir" => "test_base_dir/",
            "file_extension_test_extension" => "test_file_extension",
            "file_selector_test_file" => "test_file_selector",
            "kramdown_converter_method_test_kcm" => "test_kramdown_converter_method",
            "kramdown_parser_test_parser" => "Kramdown::Parser::Kramdown",
          }
        }
      }
      let(:json_test_config_string){ JSON.dump(valid_settings) }
      let(:config){
        c = Config.new('_')
        c.instance_variable_set(:@effective_settings, valid_settings['settings'])
        c
      }

      describe '#base_dir' do
        it "returns a specified base_dir (symbol)" do
          config.base_dir(:test_dir).must_equal 'test_base_dir/'
        end
        it "returns a specified base_dir (string)" do
          config.base_dir('test_dir').must_equal 'test_base_dir/'
        end
        it "raises on unknown name" do
          proc { config.base_dir(:unknown_key) }.must_raise ArgumentError
        end
        it "raises an ArgumentError if name does not end with '_dir'" do
          proc{ config.base_dir(:test) }.must_raise ArgumentError
        end
      end

      describe '#file_extension' do
        it "returns a specified file_extension (symbol)" do
          config.file_extension(:test_extension).must_equal 'test_file_extension'
        end
        it "returns a specified file_extension (symbol)" do
          config.file_extension('test_extension').must_equal 'test_file_extension'
        end
        it "raises on unknown name" do
          proc { config.file_extension(:unknown_key) }.must_raise ArgumentError
        end
        it "raises an ArgumentError if name does not end with '_extension' or '_extensions" do
          proc{ config.file_extension(:test_dir) }.must_raise ArgumentError
        end
      end

      describe '#file_selector' do
        it "returns a specified file_selector (symbol)" do
          config.file_selector(:test_file).must_equal 'test_file_selector'
        end
        it "returns a specified file_selector (string)" do
          config.file_selector('test_file').must_equal 'test_file_selector'
        end
        it "raises on unknown name" do
          proc { config.file_selector(:unknown_key) }.must_raise ArgumentError
        end
        it "raises an ArgumentError if name does not end with '_file' or '_files" do
          proc{ config.file_selector(:test_dir) }.must_raise ArgumentError
        end
      end

      describe '#kramdown_converter_method' do
        it "returns a specified kramdown_converter_method (symbol)" do
          config.kramdown_converter_method(:test_kcm).must_equal 'test_kramdown_converter_method'
        end
        it "returns a specified kramdown_converter_method (string)" do
          config.kramdown_converter_method('test_kcm').must_equal 'test_kramdown_converter_method'
        end
        it "raises on unknown name" do
          proc { config.kramdown_converter_method(:unknown_key) }.must_raise Repositext::Cli::RtfileError
        end
      end

      describe '#kramdown_parser' do
        it "returns a specified kramdown_parser (symbol)" do
          config.kramdown_parser(:test_parser).must_equal Kramdown::Parser::Kramdown
        end
        it "returns a specified kramdown_parser (string)" do
          config.kramdown_parser('test_parser').must_equal Kramdown::Parser::Kramdown
        end
        it "raises on unknown name" do
          proc { config.kramdown_parser(:unknown_key) }.must_raise Repositext::Cli::RtfileError
        end
      end

      describe 'Glob patterns' do

        let(:glob_settings){
          {
            "base_dir_one_dir" => '/dir/1/',
            "base_dir_two_dir" => '/dir/2/',
            "file_selector_one_files" => '**/*1*',
            "file_selector_two_files" => '**/*2*',
            "file_extension_one_extension" => '.ext1',
            "file_extension_two_extension" => '.ext2',
          }
        }
        let(:glob_config){
          c = Config.new('_')
          c.instance_variable_set(:@effective_settings, glob_settings)
          c
        }

        describe '#compute_glob_pattern' do

          it "Handles named base_dir, file_selector and file_extension from Rtfile" do
            glob_config.compute_glob_pattern(
              'one_dir', 'one_files', 'one_extension'
            ).must_equal '/dir/1/**/*1*.ext1'
          end

          it "Handles file paths" do
            glob_config.compute_glob_pattern(
              '/dir1/dir2', '**/*1*', '.at'
            ).must_equal '/dir1/dir2/**/*1*.at'
          end

        end

        describe '#compute_base_dir' do
          [
            ['one_dir', '/dir/1/'],
            ['two_dir', '/dir/2/'],
            ['/dir1',  '/dir1/'], # without trailing slash
            ['/dir1/',  '/dir1/'], # with trailing slash
            ['/dir1/dir2', '/dir1/dir2/'],
            ['/dir1/dir2/', '/dir1/dir2/'],
          ].each do |(test_string, xpect)|
            it "Handles #{ test_string.inspect }" do
              glob_config.compute_base_dir(test_string).must_equal xpect
            end
          end
        end

        describe '#compute_file_extension' do
          [
            ['one_extension', '.ext1'],
            ['two_extension', '.ext2'],
            ['.at', '.at'],
            ['.{at,txt,json}', '.{at,txt,json}'],
          ].each do |(test_string, xpect)|
            it "Handles #{ test_string.inspect }" do
              glob_config.compute_file_extension(test_string).must_equal xpect
            end
          end
        end

        describe '#compute_file_selector' do
          [
            ['one_files', '**/*1*'],
            ['two_files', '**/*2*'],
            ['*',  '*'], # without leading slash
            ['/*', '*'], # with leading slash
            ['**/*', '**/*'],
            ['file1.txt', 'file1.txt'],
          ].each do |(test_string, xpect)|
            it "Handles #{ test_string.inspect }" do
              glob_config.compute_file_selector(test_string).must_equal xpect
            end
          end
        end

      end

      # describe '#compute_validation_file_specs' do
      #   before do
      #     config.add_base_dir(:one_dir, '/dir/1/')
      #     config.add_base_dir(:two_dir, '/dir/2/')
      #     config.add_file_selector(:one_files, '**/*1*')
      #     config.add_file_selector(:two_files, '**/*2*')
      #     config.add_file_extension(:one_extension, '.ext1')
      #     config.add_file_extension(:two_extension, '.ext2')
      #   end
      #   [
      #     [
      #       {
      #         primary: ['one_dir', 'one_files', 'one_extension'],
      #         secondary: ['two_dir', 'two_files', 'two_extension']
      #       },
      #       {
      #         primary: ['/dir/1/', '**/*1*', '.ext1'],
      #         secondary: ['/dir/2/', '**/*2*', '.ext2']
      #       }
      #     ]
      #   ].each_with_index do |(input_file_specs, xpect), idx|
      #     it "handles  #{ input_file_specs.inspect }" do
      #       config.compute_validation_file_specs(input_file_specs).must_equal xpect
      #     end
      #   end

      #   it "raises if missing file_selector" do
      #     proc{
      #       config.compute_validation_file_specs(primary: [:one_dir, nil, :one_extension])
      #     }.must_raise ArgumentError
      #   end

      #   it "raises if given invalid base_dir" do
      #     proc{
      #       config.compute_validation_file_specs(primary: ['invalid_base_dir_x', 'one_files', 'one_extension'])
      #     }.must_raise ArgumentError
      #   end

      #   it "raises if given invalid file_selector" do
      #     proc{
      #       config.compute_validation_file_specs(primary: ['one_dir', 'invalid_file_selector_x', 'one_extension'])
      #     }.must_raise ArgumentError
      #   end

      #   it "raises if given invalid file_extension" do
      #     proc{
      #       config.compute_validation_file_specs(primary: ['one_dir', 'one_files', 'invalid_ext'])
      #     }.must_raise ArgumentError
      #   end
      # end

      # describe '#primary_content_type_base_dir' do
      #   before do
      #     config.add_base_dir(:content_type_dir, '/some/path/to/rtfile')
      #     config.add_setting(:relative_path_to_primary_content_type, '../../rtfile_in_primary_repo')
      #   end
      #   it "returns an absolute path to primary_content_type" do
      #     config.primary_content_type_base_dir.must_equal('/some/path/to/rtfile_in_primary_repo/')
      #   end
      # end

    end
  end
end
