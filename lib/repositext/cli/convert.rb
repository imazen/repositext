class Repositext
  class Cli
    module Convert

    private

      def convert_folio_xml_to_at(options)
        # TODO: we could allow overriding the input file pattern via an --input option
        input_file_pattern = config.file_pattern(:convert_folio_xml_to_at)
        Repositext::Cli::Utils.convert_files(
          input_file_pattern,
          /\.xml\Z/i,
          "Converting folio xml files to AT kramdown and json"
        ) do |contents, filename|
          # The Kramdown::Folio parser is an exception in that it returns a set
          # of multiple files from the parse method. On other parsers we have
          # to call `to_...` to get the output.
          docs = config.kramdown_parser(:folio_xml).new(contents).parse
          docs.keys.map do |extension|
            Outcome.new(
              true,
              { extension: extension, contents: docs[extension] }
            )
          end
        end
      end

      # Convert IDML files in /import_idml to AT
      def convert_idml_to_at(options)
        input_file_pattern = config.file_pattern(:convert_idml_to_at)
        Repositext::Cli::Utils.convert_files(
          input_file_pattern,
          /\.idml\Z/i,
          "Converting IDML files to AT kramdown"
        ) do |contents, filename|
          doc = config.kramdown_parser(:idml).new(contents).parse
          at = doc.send(config.kramdown_converter_method(:to_at))
          [Outcome.new(true, { extension: 'at', contents: at })]
        end
      end

    end
  end
end
