require_relative '../../helper'

class Repositext
  class Cli
    describe RtfileParser do

      before do
        FakeFS.activate!
        FileSystem.clear
      end

      after do
        FakeFS.deactivate!
      end

      let(:rtfile_path) { 'Rtfile' }
      let(:config) { MiniTest::Mock.new }
      let(:rtfile_parser) { RtfileParser.new(config) }

      describe '#eval_rtfile' do
        it "evaluates a valid Rtfile" do
          File.open(rtfile_path, 'w') { |f| f.write('test') }
          rtfile_parser.eval_rtfile(rtfile_path).must_equal('test successful')
        end

        it "evaluates a string instead of a file" do
          rtfile_parser.eval_rtfile(nil, 'test').must_equal('test successful')
        end
        # TODO: spec handling of errors
      end

      describe '#base_dir' do
        let(:base_dir_name) { :base_dir_name }
        let(:base_dir_string) { 'test_base_dir' }

        it "handles a block" do
          config.expect(:add_base_dir, nil, [base_dir_name, base_dir_string])
          rtfile_parser.base_dir(base_dir_name) { base_dir_string }
          assert(config.verify)
        end

        it "handles a string" do
          config.expect(:add_base_dir, nil, [base_dir_name, base_dir_string])
          rtfile_parser.base_dir(base_dir_name, base_dir_string)
          assert(config.verify)
        end

        it "raises if not given either string or block" do
          proc {
            config.expect(:add_base_dir, nil, [base_dir_name, base_dir_string])
            rtfile_parser.base_dir(base_dir_name)
          }.must_raise RtfileError
        end
      end

      describe '#file_extension' do
        let(:extension_name) { :extension_name }
        let(:extension_string) { 'test_file_extension' }

        it "handles a block" do
          config.expect(:add_file_extension, nil, [extension_name, extension_string])
          rtfile_parser.file_extension(extension_name) { extension_string }
          assert(config.verify)
        end

        it "handles a string" do
          config.expect(:add_file_extension, nil, [extension_name, extension_string])
          rtfile_parser.file_extension(extension_name, extension_string)
          assert(config.verify)
        end

        it "raises if not given either string or block" do
          proc {
            rtfile_parser.file_extension(extension_name)
          }.must_raise RtfileError
        end
      end

      describe '#file_selector' do
        let(:selector_name) { :selector_name }
        let(:selector_string) { 'test_file_selector' }

        it "handles a block" do
          config.expect(:add_file_selector, nil, [selector_name, selector_string])
          rtfile_parser.file_selector(selector_name) { selector_string }
          assert(config.verify)
        end

        it "handles a string" do
          config.expect(:add_file_selector, nil, [selector_name, selector_string])
          rtfile_parser.file_selector(selector_name, selector_string)
          assert(config.verify)
        end

        it "raises if not given either string or block" do
          proc {
            rtfile_parser.file_selector(selector_name)
          }.must_raise RtfileError
        end
      end

      describe '#kramdown_parser' do
        let(:parser_name) { :parser_name }
        let(:parser_class_name) { 'parser_class_name' }

        it "handles a string" do
          config.expect(:add_kramdown_parser, nil, [parser_name, parser_class_name])
          rtfile_parser.kramdown_parser(parser_name, parser_class_name)
          assert(config.verify)
        end
      end

      describe '#kramdown_converter_method' do
        let(:method_name) { :kramdown_converter_method_name }
        let(:kcm_name) { :kcm_name }

        it "handles a symbol" do
          config.expect(:add_kramdown_converter_method, nil, [method_name, kcm_name])
          rtfile_parser.kramdown_converter_method(method_name, kcm_name)
          assert(config.verify)
        end
      end

      describe '#method_missing' do
        it "raises when sent an unknown method" do
          proc {
            rtfile_parser.unknown_method
          }.must_raise RtfileError
        end
      end

    end
  end
end
