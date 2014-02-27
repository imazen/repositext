require 'repositext/cli'
require_relative '../../helper'

describe Repositext::Cli::Config do

  let(:config) { Repositext::Cli::Config.new }

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
  end

end
