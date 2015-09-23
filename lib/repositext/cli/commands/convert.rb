class Repositext
  class Cli
    module Convert

    private

      # Convert DOCX files in /import_docx to AT
      def convert_docx_to_at(options)
        Repositext::Cli::Utils.convert_files(
          config.compute_glob_pattern(
            options['base-dir'] || :docx_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :docx_extension
          ),
          options['file_filter'],
          "Converting DOCX files to AT kramdown",
          options.merge(input_is_binary: true)
        ) do |zip_archive_contents, filename|
          document_xml_contents = extract_word_document_xml_from_zip_archive(
            zip_archive_contents
          )
          root, warnings = config.kramdown_parser(:docx).parse(document_xml_contents)
          kramdown_doc = Kramdown::Document.new(
            '',
            { line_width: 100000 } # set to very large value so that each para is on a single line
          )
          kramdown_doc.root = root
          at = kramdown_doc.send(config.kramdown_converter_method(:to_at))
          [Outcome.new(true, { contents: at, extension: 'docx.at' })]
        end
      end

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

    private

      # Returns contents of word/document.xml file in zip_archive_contents
      # @param zip_archive_contents [String] the binary contents of zip archive
      # @return [String] XML source of word/document.xml
      def extract_word_document_xml_from_zip_archive(zip_archive_contents)
        word_document_xml = nil
        Zip::File.open_buffer(zip_archive_contents) do |zipped_files|
          word_document_xml = zipped_files.get_entry(
            'word/document.xml'
          ).get_input_stream.read
        end
        word_document_xml
      end

    end
  end
end
