class Repositext
  class Process
    class Export
      # Exports content_at_file to docx
      class Docx

        # Initializes a new exporter.
        # @param content_at_file [RFile::ContentAt]
        # @param output_filename [String] the path to save docx file to
        # @param kramdown_parser [Kramdown::Parser] to parse content AT
        # @param kramdown_converter_method [Symbol]
        def initialize(content_at_file, output_filename, kramdown_parser, kramdown_converter_method)
          @content_at_file = content_at_file
          @output_filename = output_filename
          @kramdown_parser = kramdown_parser
          @kramdown_converter_method = kramdown_converter_method
        end

        # Exports content_at_file to DOCX
        # @return [Outcome] where result is the path to the exported file
        def export
          root, _warnings = @kramdown_parser.parse(@content_at_file.contents)
          doc = Kramdown::Document.new('', { output_filename: @output_filename })
          doc.root = root
          doc.send(@kramdown_converter_method)

          Outcome.new(true, @output_filename)
        end

      end
    end
  end
end
