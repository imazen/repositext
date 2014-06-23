class Repositext
  class Cli
    module Export

    private

      # Export AT files in /content to ICML
      def export_icml(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir('icml_export_dir')
        Repositext::Cli::Utils.export_files(
          config.base_dir(input_base_dir_name),
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.at\Z/i,
          "Exporting AT files to ICML",
          options
        ) do |contents, filename|
          # We first convert AT to plain markdown to remove record_marks,
          # subtitle_marks, and gap_marks which aren't supported by ICML.
          md = convert_at_string_to_plain_markdown(contents)
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(md)
          doc = Kramdown::Document.new('')
          doc.root = root
          icml = doc.send(config.kramdown_converter_method(:to_icml))
          [Outcome.new(true, { contents: icml, extension: 'icml' })]
        end
      end

      def export_pdf_all(options)
        export_pdf_variants.each do |variant|
          self.send("export_#{ variant }", options)
        end
      end

      def export_pdf_book(options)
        # Contains everything
        case 1
        when 1
          export_pdf_base('pdf_book', options.merge('page_settings_key' => :english_bound))
        when 2
          export_pdf_base('pdf_book', options.merge('page_settings_key' => :english_regular))
        when 3
          export_pdf_base('pdf_book', options.merge('page_settings_key' => :foreign_bound))
        when 4
          export_pdf_base('pdf_book', options.merge('page_settings_key' => :foreign_regular))
        else
        end
      end

      def export_pdf_comprehensive(options)
        # Contains everything
        export_pdf_base('pdf_comprehensive', options)
      end

      def export_pdf_plain(options)
        # contains all formatting, no AT specific tokens
        export_pdf_base('pdf_plain', options)
      end

      def export_pdf_recording(options)
        export_pdf_base('pdf_recording', options)
      end

      def export_pdf_translator(options)
        export_pdf_base('pdf_translator', options)
      end

      def export_pdf_web(options)
        export_pdf_base('pdf_web', options)
      end

      # @param[String] variant one of 'pdf_plain', 'pdf_recording', 'pdf_translator'
      def export_pdf_base(variant, options)
        if !export_pdf_variants.include?(variant)
          raise(ArgumentError.new("Invalid variant: #{ variant.inspect }"))
        end
        input_file_spec = options['input'] || 'content_dir/at_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir("pdf_export_dir")
        Repositext::Cli::Utils.export_files(
          config.base_dir(input_base_dir_name),
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.at\Z/i,
          "Exporting AT files to #{ variant }",
          options
        ) do |contents, filename|
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          kramdown_doc = Kramdown::Document.new('', options.merge({ :source_filename => filename }))
          kramdown_doc.root = root
          latex_converter_method = variant.gsub(/\Apdf/, 'to_latex_repositext')
          latex = kramdown_doc.send(latex_converter_method)
          pdf = Repositext::Convert::LatexToPdf.convert(latex)

          [
            Outcome.new(
              true,
              {
                contents: pdf,
                extension: "#{ variant.split('_').last }.pdf",
                output_is_binary: true,
              }
            )
          ]
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
          md = convert_at_string_to_plain_markdown(contents)
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
              Repositext::Utils::SubtitleTaggingFilenameConverter.convert_from_repositext_to_subtitle_tagging_export(
                input_filename.gsub(config.base_dir(input_base_dir_name), output_base_dir)
              )
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
          subtitle_tagging = doc.send(config.kramdown_converter_method(:to_subtitle_tagging))
          [Outcome.new(true, { contents: subtitle_tagging, extension: 'rt.txt' })]
        end
      end

      def export_test(options)
        # dummy method for testing
        puts 'export_test'
      end

    private

      def convert_at_string_to_plain_markdown(txt)
        # Remove AT specific tokens
        Suspension::TokenRemover.new(
          txt,
          Suspension::AT_SPECIFIC_TOKENS
        ).remove
      end

      def export_pdf_variants
        %w[
          pdf_book
          pdf_comprehensive
          pdf_plain
          pdf_recording
          pdf_translator
          pdf_web
        ]
      end

    end
  end
end
