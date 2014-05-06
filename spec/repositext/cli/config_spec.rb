require_relative '../../helper'

describe Repositext::Cli::Config do

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
      proc{ config.add_base_dir(:test_dir, :test) }.wont_raise ArgumentError
    end
    it "raises an ArgumentError if name does not end with '_dir'" do
      proc{ config.add_base_dir(:test, :test) }.must_raise ArgumentError
    end
  end

  describe '#add_file_pattern' do
    it "adds a file pattern" do
      config.add_file_pattern(:test_files, 'test')
      config.file_pattern(:test_files).must_equal 'test'
    end
    it "converts name to symbol" do
      config.add_file_pattern('test_files', 'test')
      config.file_pattern(:test_files).must_equal 'test'
    end
    it "converts file_pattern to string" do
      config.add_file_pattern(:test_files, :test)
      config.file_pattern(:test_files).must_equal 'test'
    end
    it "won't raise an ArgumentError if name ends with '_file'" do
      proc{ config.add_file_pattern(:test_file, :test) }.wont_raise ArgumentError
    end
    it "won't raise an ArgumentError if name ends with '_files'" do
      proc{ config.add_file_pattern(:test_files, :test) }.wont_raise ArgumentError
    end
    it "raises an ArgumentError if name does not end with '_file' or '_files'" do
      proc{ config.add_file_pattern(:test, :test) }.must_raise ArgumentError
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
      proc{ config.base_dir(:test_dir) }.wont_raise ArgumentError
    end
    it "raises an ArgumentError if name does not end with '_dir'" do
      proc{ config.base_dir(:test) }.must_raise ArgumentError
    end
  end

  describe '#file_pattern' do
    it "returns a specified file_pattern" do
      config.add_file_pattern(:test_files, 'test')
      config.file_pattern(:test_files).must_equal 'test'
    end
    it "converts name to symbol" do
      config.add_file_pattern(:test_files, :test)
      config.file_pattern('test_files').must_equal 'test'
    end
    it "raises on unknown name" do
      proc { config.file_pattern(:unknown_key) }.must_raise ArgumentError
    end
    it "won't raise an ArgumentError if name ends with '_file'" do
      proc{ config.file_pattern(:test_file) }.wont_raise ArgumentError
    end
    it "won't raise an ArgumentError if name ends with '_files'" do
      proc{ config.file_pattern(:test_files) }.wont_raise ArgumentError
    end
    it "raises an ArgumentError if name does not end with '_file' or '_files" do
      proc{ config.file_pattern(:test) }.must_raise ArgumentError
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
      proc { config.kramdown_converter_method(:unknown_key) }.must_raise ArgumentError
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

  describe '#compute_glob_pattern' do

    describe 'named base_dir and file_pattern from Rtfile as file_spec' do
      before do
        config.add_base_dir(:one_dir, '/dir/1/')
        config.add_base_dir(:two_dir, '/dir/2/')
        config.add_file_pattern(:one_files, '**/*.ext1')
        config.add_file_pattern(:two_files, '**/*.ext2')
      end
      [
        ['one_dir/one_files', '/dir/1/**/*.ext1'],
        ['two_dir/two_files', '/dir/2/**/*.ext2'],
        ['one_dir', '/dir/1/'],
      ].each do |(file_spec, xpect)|
        it "handles '#{ file_spec }'" do
          config.compute_glob_pattern(file_spec).must_equal xpect
        end
      end
    end

    describe 'glob pattern as file_spec' do
      [
        '/dir1/*',
        '/dir1/dir2/**/*.at',
        '/dir1/dir2/file1.txt',
      ].each do |glob_pattern|
        it "handles '#{ glob_pattern }'" do
          config.compute_glob_pattern(glob_pattern).must_equal glob_pattern
        end
      end
    end

  end

  describe '#get_config_val' do
    it "raises on unknown name by default" do
      proc { config.send(:get_config_val, {}, :unknown_key) }.must_raise ArgumentError
    end
    it "doesn't raise if told so" do
      config.send(:get_config_val, {}, :unknown_key, false).must_equal nil
    end
  end

  describe '#compute_validation_file_specs' do
    before do
      config.add_base_dir(:one_dir, '/dir/1/')
      config.add_base_dir(:two_dir, '/dir/2/')
      config.add_file_pattern(:one_files, '**/*.ext1')
      config.add_file_pattern(:two_files, '**/*.ext2')
    end
    [
      [{ primary: 'one_dir/one_files' }, { primary: ['/dir/1/', '**/*.ext1'] }]
    ].each_with_index do |(input_file_specs, xpect), idx|
      it "handles scenario #{ idx + 1 }" do
        config.compute_validation_file_specs(input_file_specs).must_equal xpect
      end
    end

    it "raises if given invalid file_specs" do
      proc{
        config.compute_validation_file_specs(primary: 'without_forward_slash')
      }.must_raise ArgumentError
    end

    it "raises if given invalid base_dir" do
      proc{
        config.compute_validation_file_specs(primary: 'invalid_base_dir_x/file_pattern_files')
      }.must_raise ArgumentError
    end

    it "raises if given invalid file_pattern" do
      proc{
        config.compute_validation_file_specs(primary: 'base_dir/invalid_file_pattern_x')
      }.must_raise ArgumentError
    end
  end
end
