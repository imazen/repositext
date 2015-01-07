require_relative '../../helper'

class Repositext
  class Cli
    describe RtfileDsl do

      before do
        FakeFS.activate!
        FileSystem.clear
      end

      after do
        FakeFS.deactivate!
      end

      let(:klass) {
        Class.new {
          include RtfileDsl
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
          instance_with_config.config = Config.new
          File.open('Rtfile', 'w') { |f| f.write('test') }
          instance_with_config.eval_rtfile('Rtfile').must_equal 'test successful'
        end

        it "evaluates a string instead of a file" do
          instance_with_config.config = Config.new
          instance_with_config.eval_rtfile(nil, 'test').must_equal 'test successful'
        end
        # TODO: spec handling of errors
      end

      describe '#base_dir' do
        let(:base_dir_name) { :base_dir_name }
        let(:base_dir_string) { 'test_base_dir' }
        let(:conf) { MiniTest::Mock.new }

        it "handles a block" do
          conf.expect(:add_base_dir, nil, [base_dir_name, base_dir_string])
          instance_with_config.config = conf

          instance_with_config.base_dir(base_dir_name) { base_dir_string }

          assert conf.verify
        end

        it "handles a string" do
          conf.expect(:add_base_dir, nil, [base_dir_name, base_dir_string])
          instance_with_config.config = conf

          instance_with_config.base_dir(base_dir_name, base_dir_string)

          assert conf.verify
        end

        it "raises if not given either string or block" do
          proc {
            instance.base_dir(base_dir_name)
          }.must_raise RtfileError
        end
      end

      describe '#file_extension' do
        let(:extension_name) { :extension_name }
        let(:extension_string) { 'test_file_extension' }
        let(:conf) { MiniTest::Mock.new }

        it "handles a block" do
          conf.expect(:add_file_extension, nil, [extension_name, extension_string])
          instance_with_config.config = conf

          instance_with_config.file_extension(extension_name) { extension_string }

          assert conf.verify
        end

        it "handles a string" do
          conf.expect(:add_file_extension, nil, [extension_name, extension_string])
          instance_with_config.config = conf

          instance_with_config.file_extension(extension_name, extension_string)

          assert conf.verify
        end

        it "raises if not given either string or block" do
          proc {
            instance.file_extension(extension_name)
          }.must_raise RtfileError
        end
      end

      describe '#file_selector' do
        let(:selector_name) { :selector_name }
        let(:selector_string) { 'test_file_selector' }
        let(:conf) { MiniTest::Mock.new }

        it "handles a block" do
          conf.expect(:add_file_selector, nil, [selector_name, selector_string])
          instance_with_config.config = conf

          instance_with_config.file_selector(selector_name) { selector_string }

          assert conf.verify
        end

        it "handles a string" do
          conf.expect(:add_file_selector, nil, [selector_name, selector_string])
          instance_with_config.config = conf

          instance_with_config.file_selector(selector_name, selector_string)

          assert conf.verify
        end

        it "raises if not given either string or block" do
          proc {
            instance.file_selector(selector_name)
          }.must_raise RtfileError
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
          }.must_raise RtfileError
        end
      end

    end
  end
end
