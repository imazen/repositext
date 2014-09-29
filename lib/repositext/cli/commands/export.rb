class Repositext
  class Cli
    module Export

    private

      # Export Gap mark Tagging files
      def export_gap_mark_tagging(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir('gap_mark_tagging_export_dir')
        Repositext::Cli::Utils.export_files(
          config.base_dir(input_base_dir_name),
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.at\Z/i,
          "Exporting AT files to gap_mark tagging",
          options.merge(
            :output_path_lambda => lambda { |input_filename, output_file_attrs|
              input_filename.gsub(config.base_dir(input_base_dir_name), output_base_dir)
                            .gsub(/\.at\z/, '.gap_mark_tagging.txt')
            }
          )
        ) do |contents, filename|
          outcome = Repositext::Export::GapMarkTagging.export(contents)
          if outcome.success?
            [Outcome.new(true, { contents: outcome.result, extension: 'gap_mark_tagging.txt' })]
          else
            outcome
          end
        end
      end

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
        case
        when config.setting(:is_primary_repo) && true # TODO: add check for bound or regular
          export_pdf_base(
            'pdf_book',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :english_regular,
            )
          )
        when config.setting(:is_primary_repo) && false # TODO: add check for bound or regular
          export_pdf_base(
            'pdf_book',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :english_bound,
            )
          )
        when !config.setting(:is_primary_repo) && true # TODO: add check for bound or regular
          export_pdf_base(
            'pdf_book',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :foreign_regular,
            )
          )
        when !config.setting(:is_primary_repo) && false # TODO: add check for bound or regular
          export_pdf_base(
            'pdf_book',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :foreign_bound,
            )
          )
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
        # Skip files that don't contain gap_marks
        skip_file_proc = Proc.new { |contents, filename| !contents.index('%') }
        export_pdf_base(
          'pdf_recording',
          options.merge(:skip_file_proc => skip_file_proc)
        )
      end

      def export_pdf_translator(options)
        export_pdf_base('pdf_translator', options)
      end

      def export_pdf_web(options)
        case
        when config.setting(:is_primary_repo)
          export_pdf_base(
            'pdf_web',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :english_regular,
            )
          )
        else
          export_pdf_base(
            'pdf_web',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :foreign_regular,
            )
          )
        end
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
          if options[:skip_file_proc] && options[:skip_file_proc].call(contents, filename)
            $stderr.puts " - Skipping #{ filename } - matches options[:skip_file_proc]"
            next([Outcome.new(true, { contents: nil })])
          end
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          kramdown_doc = Kramdown::Document.new(
            '',
            options.merge({
              :additional_footer_text => options['additional-footer-text'],
              :header_text => config.setting(:pdf_export_header_text),
              :is_primary_repo => config.setting(:is_primary_repo),
              :source_filename => filename,
              :version_control_page => options['include-version-control-info'],
            })
          )
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


      # Export Subtitle files
      def export_subtitle(options)
        input_file_spec = options['input'] || 'content_dir/at_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        input_base_dir = config.base_dir(input_base_dir_name)
        output_base_dir = options['output'] || config.base_dir('subtitle_export_dir')
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.at\Z/i,
          "Exporting AT files to subtitle",
          options.merge(
            :output_path_lambda => lambda { |input_filename, output_file_attrs|
              Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_export(
                input_filename.gsub(input_base_dir, output_base_dir),
                output_file_attrs
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
          subtitle = doc.send(config.kramdown_converter_method(:to_subtitle))
          [Outcome.new(true, { contents: subtitle, extension: 'txt' })]
        end
        copy_subtitle_marker_csv_files_to_subtitle_export(options)
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
              Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_export(
                input_filename.gsub(config.base_dir(input_base_dir_name), output_base_dir),
                output_file_attrs
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
          empty_markers_file = %(RelativeMS\tSamples\n0\t0\n)
          [
            Outcome.new(true, { contents: subtitle_tagging, extension: 'rt.txt' }),
            Outcome.new(true, { contents: empty_markers_file, extension: 'markers.txt' }),
          ]
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
