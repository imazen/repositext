class Repositext
  class Cli
    module Export

    private

      # Export PT files in /content to ICML
      def export_icml(options)
        input_file_spec = options['input'] || 'content_dir/pt_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir('icml_export_dir')
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
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          icml = doc.send(config.kramdown_converter_method(:to_icml))
          [Outcome.new(true, { contents: icml, extension: 'icml' })]
        end
      end

      # Export AT files in /content to plain kramdown (no record_marks,
      # subtitle_marks, or gap_marks)
      def export_plain_kramdown(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir('plain_kramdown_export_dir')
        Repositext::Cli::Utils.export_files(
          config.base_dir(input_base_dir_name),
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.md\Z/i,
          "Exporting AT files to plain kramdown",
          options
        ) do |contents, filename|
          # Remove AT specific tokens
          md = Suspension::TokenRemover.new(
            contents,
            Suspension::AT_SPECIFIC_TOKENS
          ).remove
          [Outcome.new(true, { contents: md, extension: '.md' })]
        end
      end


      # Export Subtitle Tagging files
      def export_subtitle_tagging(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir('subtitle_tagging_export_dir')
        Repositext::Cli::Utils.export_files(
          config.base_dir(input_base_dir_name),
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.at\Z/i,
          "Exporting AT files to subtitle tagging",
          options.merge(
            :output_path_lambda => lambda { |input_filename, output_file_attrs|
              # convert
              # /content/47/eng47-0412_0002.at
              # =>
              # /subtitle_tagging_export/47/47-0412_0002.en.rt.txt
              input_filename.gsub(config.base_dir(input_base_dir_name), output_base_dir)
                            .gsub(/\/eng/, '/')
                            .gsub(/\.at\z/, '.en.rt.txt')
            }
          )
        ) do |contents, filename|
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          subtitle_tagging = doc.to_subtitle_tagging
          [Outcome.new(true, { contents: subtitle_tagging, extension: 'rt.txt' })]
        end
      end

      def export_test(options)
        # dummy method for testing
        puts 'export_test'
      end

    end
  end
end
