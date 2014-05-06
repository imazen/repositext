require_relative '../../helper'

describe Repositext::Cli::RtfileDsl do

  before do
    FakeFS.activate!
    FileSystem.clear
  end

  after do
    FakeFS.deactivate!
  end

  let(:klass) {
    Class.new {
      include Repositext::Cli::RtfileDsl
      attr_accessor :config
    }
  }
  let(:instance) { klass.new }
  let(:instance_with_config) { klass.new } # use this instance when testing with #config

  describe '.find_rtfile' do
    it "finds Rtfile in current directory" do
      FileUtils.cd '/'
      FileUtils.touch 'Rtfile'
      klass.find_rtfile.must_equal '/Rtfile'
    end

    it "finds Rtfile in ancestor directory" do
      p = '/path1/path2'
      FileUtils.mkdir_p p
      FileUtils.cd '/path1'
      FileUtils.touch 'Rtfile'
      FileUtils.cd 'path2'
      klass.find_rtfile.must_equal '/path1/Rtfile'
    end

    it "returns nil if no Rtfile can be found" do
      klass.find_rtfile.must_equal nil
    end
  end

  describe '#eval_rtfile' do
    it "evaluates a valid Rtfile" do
      instance_with_config.config = Repositext::Cli::Config.new
      File.open('Rtfile', 'w') { |f| f.write('test') }
      instance_with_config.eval_rtfile('Rtfile').must_equal 'test successful'
    end

    it "evaluates a string instead of a file" do
      instance_with_config.config = Repositext::Cli::Config.new
      instance_with_config.eval_rtfile(nil, 'test').must_equal 'test successful'
    end
    # TODO: spec handling of errors
  end

  describe '#file_pattern' do
    let(:pattern_name) { :pattern_name }
    let(:pattern_string) { 'test_file_pattern' }
    let(:conf) { MiniTest::Mock.new }

    it "handles a block" do
      conf.expect(:add_file_pattern, nil, [pattern_name, pattern_string])
      instance_with_config.config = conf

      instance_with_config.file_pattern(pattern_name) { pattern_string }

      assert conf.verify
    end

    it "handles a string" do
      conf.expect(:add_file_pattern, nil, [pattern_name, pattern_string])
      instance_with_config.config = conf

      instance_with_config.file_pattern(pattern_name, pattern_string)

      assert conf.verify
    end

    it "raises if not given either string or block" do
      proc {
        instance.file_pattern(pattern_name)
      }.must_raise Repositext::Cli::RtfileError
    end
  end

  describe '#kramdown_parser' do
    let(:parser_name) { :parser_name }
    let(:parser_class_name) { 'parser_class_name' }
    let(:conf) { MiniTest::Mock.new }

    it "handles a string" do
      conf.expect(:add_kramdown_parser, nil, [parser_name, parser_class_name])
      instance_with_config.config = conf

      instance_with_config.kramdown_parser(parser_name, parser_class_name)

      assert conf.verify
    end
  end

  describe '#kramdown_converter_method' do
    let(:method_name) { :kramdown_converter_method_name }
    let(:kcm_name) { :kcm_name }
    let(:conf) { MiniTest::Mock.new }

    it "handles a symbol" do
      conf.expect(:add_kramdown_converter_method, nil, [method_name, kcm_name])
      instance_with_config.config = conf

      instance_with_config.kramdown_converter_method(method_name, kcm_name)

      assert conf.verify
    end
  end

  describe '#method_missing' do
    it "raises when sent an unknown method" do
      proc {
        instance.unknown_method
      }.must_raise Repositext::Cli::RtfileError
    end
  end

end
