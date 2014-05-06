class Repositext
  class Cli
    module Export

    private

      # Export PT files in /content to ICML
      def export_to_icml(options)
        input_file_spec = options['input'] || 'content_dir/pt_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir('export_icml_dir')
        Repositext::Cli::Utils.export_files(
          config.base_dir(input_base_dir_name),
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.md\Z/i,
          "Exporting PT files to ICML",
          options
        ) do |contents, filename|
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it to icml.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          icml = doc.send(config.kramdown_converter_method(:to_icml))
          [Outcome.new(true, { contents: icml, extension: 'icml' })]
        end
      end

      def export_test(options)
        # dummy method for testing
        puts 'export_test'
      end

    end
  end
end
