class Repositext
  class Cli
    module Convert

    private

      def convert_folio_xml_to_at(options)
        Repositext::Cli::Utils.convert_files(
          config.compute_glob_pattern(
            options['base-dir'] || :folio_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :xml_extension
          ),
          options['file_filter'],
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
        Repositext::Cli::Utils.convert_files(
          config.compute_glob_pattern(
            options['base-dir'] || :idml_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :idml_extension
          ),
          options['file_filter'],
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
