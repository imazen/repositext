require 'repositext/cli'
require_relative '../../helper'

describe Repositext::Cli::Config do

  let(:config) { Repositext::Cli::Config.new }

  describe '#rtfile_dir' do
    it "has an accessor" do
      config.rtfile_dir = '123'
      config.rtfile_dir.must_equal '123'
    end
  end

  describe '#add_file_pattern' do
    it "adds a file pattern" do
      config.add_file_pattern(:test, 'test')
      config.file_pattern(:test).must_equal 'test'
    end
    it "converts name to symbol" do
      config.add_file_pattern('test', 'test')
      config.file_pattern(:test).must_equal 'test'
    end
    it "converts file_pattern to string" do
      config.add_file_pattern(:test, :test)
      config.file_pattern(:test).must_equal 'test'
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

  describe '#file_pattern' do
    it "returns a specified file_pattern" do
      config.add_file_pattern(:test, 'test')
      config.file_pattern(:test).must_equal 'test'
    end
    it "converts name to symbol" do
      config.add_file_pattern(:test, :test)
      config.file_pattern('test').must_equal 'test'
    end
    it "raises on unknown name" do
      proc { config.file_pattern(:unknown_key) }.must_raise ArgumentError
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

  describe '#get_config_val' do
    it "raises on unknown name by default" do
      proc { config.send(:get_config_val, {}, :unknown_key) }.must_raise ArgumentError
    end
    it "doesn't raise if told so" do
      config.send(:get_config_val, {}, :unknown_key, false).must_equal nil
    end
  end

end
