require_relative '../../../helper'

class Repositext
  class Cli
    class Config
      describe FromRtfile do

        let(:rtfile_path) { 'Rtfile' }
        let(:from_rtfile) { FromRtfile.new(rtfile_path) }

        describe '#load' do
          it "loads a valid Rtfile" do
            File.open(rtfile_path, 'w') { |f| f.write('test') }
            from_rtfile.load.must_equal({ "test"=>"test successful" })
          end

          # TODO: spec handling of errors
        end

        describe '#base_dir' do
          let(:base_dir_name) { :base_dir_name }
          let(:base_dir_string) { 'test_base_dir' }

          it "handles a block" do
            from_rtfile.base_dir(base_dir_name) { base_dir_string }
            from_rtfile.settings.must_equal(
              {"base_dir_base_dir_name"=> base_dir_string }
            )
          end

          it "handles a string" do
            from_rtfile.base_dir(base_dir_name, base_dir_string)
            from_rtfile.settings.must_equal(
              {"base_dir_base_dir_name"=> base_dir_string }
            )
          end

          it "raises if not given either string or block" do
            proc {
              from_rtfile.base_dir(base_dir_name)
            }.must_raise RtfileError
          end
        end

        describe '#file_extension' do
          let(:extension_name) { :extension_name }
          let(:extension_string) { 'test_file_extension' }

          it "handles a block" do
            from_rtfile.file_extension(extension_name) { extension_string }
            from_rtfile.settings.must_equal(
              {"file_extension_extension_name"=> extension_string }
            )
          end

          it "handles a string" do
            from_rtfile.file_extension(extension_name, extension_string)
            from_rtfile.settings.must_equal(
              {"file_extension_extension_name"=> extension_string }
            )
          end

          it "raises if not given either string or block" do
            proc {
              from_rtfile.file_extension(extension_name)
            }.must_raise RtfileError
          end
        end

        describe '#file_selector' do
          let(:selector_name) { :selector_name }
          let(:selector_string) { 'test_file_selector' }

          it "handles a block" do
            from_rtfile.file_selector(selector_name) { selector_string }
            from_rtfile.settings.must_equal(
              {"file_selector_selector_name"=> selector_string }
            )
          end

          it "handles a string" do
            from_rtfile.file_selector(selector_name, selector_string)
            from_rtfile.settings.must_equal(
              {"file_selector_selector_name"=> selector_string }
            )
          end

          it "raises if not given either string or block" do
            proc {
              from_rtfile.file_selector(selector_name)
            }.must_raise RtfileError
          end
        end

        describe '#kramdown_parser' do
          let(:parser_name) { :parser_name }
          let(:parser_class_name) { 'parser_class_name' }

          it "handles a string" do
            from_rtfile.kramdown_parser(parser_name, parser_class_name)
            from_rtfile.settings.must_equal(
              {"kramdown_parser_parser_name"=> parser_class_name }
            )
          end
        end

        describe '#kramdown_converter_method' do
          let(:method_name) { :kramdown_converter_method_name }
          let(:kcm_name) { :kcm_name }

          it "handles a symbol" do
            from_rtfile.kramdown_converter_method(method_name, kcm_name)
            from_rtfile.settings.must_equal(
              {"kramdown_converter_method_kramdown_converter_method_name"=> kcm_name }
            )
          end
        end

        describe '#method_missing' do
          it "raises when sent an unknown method" do
            proc {
              from_rtfile.unknown_method
            }.must_raise RtfileError
          end
        end

      end
    end
  end
end
