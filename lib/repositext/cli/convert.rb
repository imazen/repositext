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
          docs = config.parser(:folio).new(contents).parse
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
          doc = config.parser(:idml).new(contents).parse
          [Outcome.new(true, { extension: 'at', contents: doc })]
        end
      end

    end
  end
end
