require_relative '../../../helper'

class Repositext
  class Process
    class Convert

      describe DocxToAt do

        let(:docx_kramdown_parser){ Kramdown::Parser::Docx }
        let(:document_xml){ File.read(File.expand_path('../docx_to_at/document.xml', __FILE__)) }
        let(:at_kramdown_converter_method){ :to_kramdown }
        let(:docx_file){ RFile::Binary.new('', Language::English.new, 'filename') }
        let(:default_converter){
          DocxToAt.new(document_xml, docx_file, docx_kramdown_parser, at_kramdown_converter_method)
        }
        let(:expected_at){ File.read(File.expand_path('../docx_to_at/converted.at', __FILE__)) }

        describe '#convert' do

          it 'converts default data to at' do
            o = default_converter.convert
            o.result.must_equal(expected_at)
          end

        end

      end

    end
  end
end
