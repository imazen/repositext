class Repositext
  class Cli
    module Convert

    private

      def convert_folio_xml_to_at(options)
        input_file_spec = options[:input] || 'import_folio_xml_dir.xml_files'
        Repositext::Cli::Utils.convert_files(
          config.compute_glob_pattern(input_file_spec),
          /\.xml\Z/i,
          "Converting folio xml files to AT kramdown and json",
          options
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
        input_file_spec = options[:input] || 'import_idml_dir.idml_files'
        Repositext::Cli::Utils.convert_files(
          config.compute_glob_pattern(input_file_spec),
          /\.idml\z/i,
          "Converting IDML files to AT kramdown",
          options.merge(input_is_binary: true)
        ) do |contents, filename|
          doc = config.kramdown_parser(:idml).new(contents).parse
          at = doc.send(config.kramdown_converter_method(:to_at))
          [Outcome.new(true, { contents: at, extension: 'idml.at' })]
        end
      end

      def convert_test(options)
        # dummy method for testing
        puts 'convert_test'
      end

    end
  end
end
