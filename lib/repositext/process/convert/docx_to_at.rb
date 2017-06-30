class Repositext
  class Process
    class Convert
      # Converts a DOCX XML document to kramdown AT string.
      class DocxToAt

        # @param document_xml [String] contents of 'word/document.xml' in ZIP archive
        # @param docx_file [Repositext::RFile::Docx]
        # @param docx_kramdown_parser [Class], e.g., Kramdown::Parser::Docx
        # @param at_kramdown_converter_method [Symbol], e.g., :to_at
        def initialize(document_xml, docx_file, docx_kramdown_parser, at_kramdown_converter_method)
          raise ArgumentError.new("Invalid document_xml")  unless document_xml.is_a?(String)
          raise ArgumentError.new("Invalid docx_file: #{ docx_file.inspect }")  unless docx_file.is_a?(RFile::Docx)
          @document_xml = document_xml
          @docx_file = docx_file
          @docx_kramdown_parser = docx_kramdown_parser
          @at_kramdown_converter_method = at_kramdown_converter_method
        end

        # Converts document_xml to content_at
        # @return [Outcome] with imported content AT String as result
        def convert
          root, _warnings = @docx_kramdown_parser.parse(@document_xml)
          kramdown_doc = Kramdown::Document.new(
            '',
            { line_width: 100000 } # set to very large value so that each para is on a single line
          )
          kramdown_doc.root = root
          at = kramdown_doc.send(@at_kramdown_converter_method)
          Outcome.new(true, at)
        end

      end
    end
  end
end
