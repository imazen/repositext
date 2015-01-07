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

      let(:config) { Repositext::Cli::Config.new }

      describe '#add_base_dir' do
        it "adds a base dir" do
          config.add_base_dir(:test_dir, 'test/')
          config.base_dir(:test_dir).must_equal 'test/'
        end
        it "converts name to symbol" do
          config.add_base_dir('test_dir', 'test/')
          config.base_dir(:test_dir).must_equal 'test/'
        end
        it "converts base_dir to string" do
          config.add_base_dir(:test_dir, :'test/')
          config.base_dir(:test_dir).must_equal 'test/'
        end
        it "adds a trailing slash if none is present" do
          config.add_base_dir(:test_dir, 'test')
          config.base_dir(:test_dir).must_equal 'test/'
        end
        it "won't raise an ArgumentError if name ends with '_dir'" do
          config.add_base_dir(:test_dir, :test)
          1.must_equal(1)
        end
        it "raises an ArgumentError if name does not end with '_dir'" do
          proc{ config.add_base_dir(:test, :test) }.must_raise ArgumentError
        end
      end

      describe '#add_file_extension' do
        it "adds a file extension" do
          config.add_file_extension(:test_extension, 'test')
          config.file_extension(:test_extension).must_equal 'test'
        end
        it "converts name to symbol" do
          config.add_file_extension('test_extension', 'test')
          config.file_extension(:test_extension).must_equal 'test'
        end
        it "converts file_extension to string" do
          config.add_file_extension(:test_extension, :test)
          config.file_extension(:test_extension).must_equal 'test'
        end
        it "won't raise an ArgumentError if name ends with '_extension'" do
          config.add_file_extension(:test_extension, :test)
          1.must_equal(1)
        end
        it "won't raise an ArgumentError if name ends with '_extensions'" do
          config.add_file_extension(:test_extensions, :test)
          1.must_equal(1)
        end
        it "raises an ArgumentError if name does not end with '_file' or '_files'" do
          proc{ config.add_file_extension(:test, :test) }.must_raise ArgumentError
        end
      end

      describe '#add_file_selector' do
        it "adds a file selector" do
          config.add_file_selector(:test_file, 'test')
          config.file_selector(:test_file).must_equal 'test'
        end
        it "converts name to symbol" do
          config.add_file_selector('test_file', 'test')
          config.file_selector(:test_file).must_equal 'test'
        end
        it "converts file_selector to string" do
          config.add_file_selector(:test_file, :test)
          config.file_selector(:test_file).must_equal 'test'
        end
        it "won't raise an ArgumentError if name ends with '_files'" do
          config.add_file_selector(:test_files, :test)
          1.must_equal(1)
        end
        it "won't raise an ArgumentError if name ends with '_files'" do
          config.add_file_selector(:test_file, :test)
          1.must_equal(1)
        end
        it "raises an ArgumentError if name does not end with '_file' or '_files'" do
          proc{ config.add_file_selector(:test, :test) }.must_raise ArgumentError
        end
      end

      describe '#add_kramdown_converter_method' do
        it "adds a kramdown converter method" do
          config.add_kramdown_converter_method(:test, :test)
          config.kramdown_converter_method(:test).must_equal :test
        end
        it "converts name to symbol" do
          config.add_kramdown_converter_method('test', :test)
          config.kramdown_converter_method(:test).must_equal :test
        end
        it "converts method_name to symbol" do
          config.add_kramdown_converter_method(:test, 'test')
          config.kramdown_converter_method(:test).must_equal :test
        end
      end

      describe '#add_kramdown_parser' do
        it "adds a kramdown parser" do
          config.add_kramdown_parser(:test, 'Kramdown::Parser::Kramdown')
          config.kramdown_parser(:test).must_equal Kramdown::Parser::Kramdown
        end
        it "converts name to symbol" do
          config.add_kramdown_parser('test', 'Kramdown::Parser::Kramdown')
          config.kramdown_parser(:test).must_equal Kramdown::Parser::Kramdown
        end
        it "converts class_name to Class" do
          config.add_kramdown_parser(:test, 'Kramdown::Parser::Kramdown')
          config.kramdown_parser(:test).must_equal Kramdown::Parser::Kramdown
        end
      end

      describe '#base_dir' do
        it "returns a specified base_dir" do
          config.add_base_dir(:test_dir, 'test/')
          config.base_dir(:test_dir).must_equal 'test/'
        end
        it "converts name to symbol" do
          config.add_base_dir(:test_dir, 'test/')
          config.base_dir('test_dir').must_equal 'test/'
        end
        it "raises on unknown name" do
          proc { config.base_dir(:unknown_key) }.must_raise ArgumentError
        end
        it "won't raise an ArgumentError if name ends with '_dir'" do
          config.add_base_dir(:test_dir, 'test')
          config.base_dir(:test_dir).must_equal('test/')
        end
        it "raises an ArgumentError if name does not end with '_dir'" do
          proc{ config.base_dir(:test) }.must_raise ArgumentError
        end
      end

      describe '#file_extension' do
        it "returns a specified file_extension" do
          config.add_file_extension(:test_extension, 'test')
          config.file_extension(:test_extension).must_equal 'test'
        end
        it "converts name to symbol" do
          config.add_file_extension(:test_extension, :test)
          config.file_extension('test_extension').must_equal 'test'
        end
        it "raises on unknown name" do
          proc { config.file_extension(:unknown_key) }.must_raise ArgumentError
        end
        it "won't raise an ArgumentError if name ends with '_extensions'" do
          config.add_file_extension(:test_extensions, :test)
          config.file_extension(:test_extensions).must_equal('test')
        end
        it "won't raise an ArgumentError if name ends with '_extension'" do
          config.add_file_extension(:test_extension, :test)
          config.file_extension(:test_extension).must_equal('test')
        end
        it "raises an ArgumentError if name does not end with '_file' or '_files" do
          proc{ config.file_extension(:test) }.must_raise ArgumentError
        end
      end

      describe '#file_selector' do
        it "returns a specified file_selector" do
          config.add_file_selector(:test_files, 'test')
          config.file_selector(:test_files).must_equal 'test'
        end
        it "converts name to symbol" do
          config.add_file_selector(:test_files, :test)
          config.file_selector('test_files').must_equal 'test'
        end
        it "raises on unknown name" do
          proc { config.file_selector(:unknown_key) }.must_raise ArgumentError
        end
        it "won't raise an ArgumentError if name ends with '_file'" do
          config.add_file_selector(:test_file, :test)
          config.file_selector(:test_file).must_equal('test')
        end
        it "won't raise an ArgumentError if name ends with '_files'" do
          config.add_file_selector(:test_files, :test)
          config.file_selector(:test_files).must_equal('test')
        end
        it "raises an ArgumentError if name does not end with '_file' or '_files" do
          proc{ config.file_selector(:test) }.must_raise ArgumentError
        end
      end

      describe '#kramdown_converter_method' do
        it "returns a specified kramdown_converter_method" do
          config.add_kramdown_converter_method(:test, :test)
          config.kramdown_converter_method(:test).must_equal :test
        end
        it "converts name to symbol" do
          config.add_kramdown_converter_method(:test, :test)
          config.kramdown_converter_method('test').must_equal :test
        end
        it "raises on unknown name" do
          proc { config.kramdown_converter_method(:unknown_key) }.must_raise Repositext::Cli::RtfileError
        end
      end

      describe '#kramdown_parser' do
        it "returns a specified kramdown_parser" do
          config.add_kramdown_parser(:test, 'Kramdown::Parser::Kramdown')
          config.kramdown_parser(:test).must_equal Kramdown::Parser::Kramdown
        end
        it "converts name to symbol" do
          config.add_kramdown_parser(:test, 'Kramdown::Parser::Kramdown')
          config.kramdown_parser('test').must_equal Kramdown::Parser::Kramdown
        end
        it "raises on unknown name" do
          proc { config.add_kramdown_parser(:unknown_key) }.must_raise ArgumentError
        end
      end

      describe 'Glob patterns' do

        before do
          config.add_base_dir(:one_dir, '/dir/1/')
          config.add_base_dir(:two_dir, '/dir/2/')
          config.add_file_selector(:one_files, '**/*1*')
          config.add_file_selector(:two_files, '**/*2*')
          config.add_file_extension(:one_extension, '.ext1')
          config.add_file_extension(:two_extension, '.ext2')
        end

        describe '#compute_glob_pattern' do

          it "Handles named base_dir, file_selector and file_extension from Rtfile" do
            config.compute_glob_pattern('one_dir', 'one_files', 'one_extension').must_equal '/dir/1/**/*1*.ext1'
          end

          it "Handles file paths" do
            config.compute_glob_pattern('/dir1/dir2', '**/*1*', '.at').must_equal '/dir1/dir2/**/*1*.at'
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
              config.compute_base_dir(test_string).must_equal xpect
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
              config.compute_file_extension(test_string).must_equal xpect
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
              config.compute_file_selector(test_string).must_equal xpect
            end
          end
        end

      end

      describe '#get_config_val' do
        it "raises on unknown name by default" do
          proc { config.send(:get_config_val, {}, :unknown_key) }.must_raise Repositext::Cli::RtfileError
        end
        it "doesn't raise if told so" do
          config.send(:get_config_val, {}, :unknown_key, false).must_equal nil
        end
      end

      describe '#compute_validation_file_specs' do
        before do
          config.add_base_dir(:one_dir, '/dir/1/')
          config.add_base_dir(:two_dir, '/dir/2/')
          config.add_file_selector(:one_files, '**/*1*')
          config.add_file_selector(:two_files, '**/*2*')
          config.add_file_extension(:one_extension, '.ext1')
          config.add_file_extension(:two_extension, '.ext2')
        end
        [
          [
            {
              primary: ['one_dir', 'one_files', 'one_extension'],
              secondary: ['two_dir', 'two_files', 'two_extension']
            },
            {
              primary: ['/dir/1/', '**/*1*', '.ext1'],
              secondary: ['/dir/2/', '**/*2*', '.ext2']
            }
          ]
        ].each_with_index do |(input_file_specs, xpect), idx|
          it "handles  #{ input_file_specs.inspect }" do
            config.compute_validation_file_specs(input_file_specs).must_equal xpect
          end
        end

        it "raises if missing file_selector" do
          proc{
            config.compute_validation_file_specs(primary: [:one_dir, nil, :one_extension])
          }.must_raise ArgumentError
        end

        it "raises if given invalid base_dir" do
          proc{
            config.compute_validation_file_specs(primary: ['invalid_base_dir_x', 'one_files', 'one_extension'])
          }.must_raise ArgumentError
        end

        it "raises if given invalid file_selector" do
          proc{
            config.compute_validation_file_specs(primary: ['one_dir', 'invalid_file_selector_x', 'one_extension'])
          }.must_raise ArgumentError
        end

        it "raises if given invalid file_extension" do
          proc{
            config.compute_validation_file_specs(primary: ['one_dir', 'one_files', 'invalid_ext'])
          }.must_raise ArgumentError
        end
      end

      describe '#primary_repo_base_dir' do
        before do
          config.add_base_dir(:rtfile_dir, '/some/path/to/rtfile')
          config.add_setting(:relative_path_to_primary_repo, '../rtfile_in_primary_repo')
        end
        it "returns an absolute path to primary_repo" do
          config.primary_repo_base_dir.must_equal('/some/path/to/rtfile_in_primary_repo/')
        end
      end

    end
  end
end
