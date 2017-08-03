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
        # @param font_names [Hash] with keys [:font_name, :id_title_font_name, :title_font_name]
        def initialize(content_at_file, output_filename, kramdown_parser, kramdown_converter_method, font_names)
          @content_at_file = content_at_file
          @output_filename = output_filename
          @kramdown_parser = kramdown_parser
          @kramdown_converter_method = kramdown_converter_method
          @font_names = font_names
        end

        # Exports content_at_file to DOCX
        # @return [Outcome] where result is the path to the exported file
        def export
          raw_content_at = @content_at_file.contents
          prepared_content_at = prepare_content_at(raw_content_at)
          root, _warnings = @kramdown_parser.parse(prepared_content_at)
          doc = Kramdown::Document.new(
            '',
            {
              output_filename: @output_filename,
              font_names: @font_names,
            }
          )
          doc.root = root
          doc.send(@kramdown_converter_method)

          Outcome.new(true, @output_filename)
        end

      protected

        def prepare_content_at(raw_content_at)
          r = raw_content_at.dup
          # Replace space after leading eagles with tab, or insert tab if there is no space
          # ImplementationTag #eagles_regex
          r.gsub!(
            /
              ( # capture group 1
                ^ # beginning of line
                [@%]* # optional subtitle and or gap mark
                 # eagle
              )
              \s* # zero or more whitespace chars
              ( # capture group 2
                [^\s]{1} # one non-whitespace char
              )
            /x,
            '\1' + "\t" + '\2' # insert tab, or replace whitespace with tab
          )
          # Replace space before trailing eagles with tab, or insert tab if there is no space
          # ImplementationTag #eagles_regex
          r.gsub!(
            /
              (?!<^) # not preceded by line start
              ( # first capture group
                [^\s]{1} # one non eagle or whitespace char
              )
              \s # zero or more whitespace characters
              ( # second capture group
                 # eagle
                [^]{,3} # up to three non eagle chars
                $ # end of line
              )
            /x,
            '\1' + "\t" + '\2' # replace space with tab, or insert tab
          )
          r
        end

      end
    end
  end
end
