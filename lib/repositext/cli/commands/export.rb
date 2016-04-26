class Repositext
  class Cli
    module Export

    private

      # Export Gap mark Tagging files
      def export_gap_mark_tagging(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:gap_mark_tagging_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to gap_mark tagging",
          options.merge(
            :output_path_lambda => lambda { |input_filename, output_file_attrs|
              input_filename.gsub(input_base_dir, output_base_dir)
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
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:icml_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
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

      def export_pdf_book_bound(options)
        if config.setting(:is_primary_repo)
          export_pdf_base(
            'pdf_book_bound',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :english_bound,
            )
          )
        else
          export_pdf_base(
            'pdf_book_bound',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :foreign_bound,
            )
          )
        end
      end

      def export_pdf_book_regular(options)
        if config.setting(:is_primary_repo)
          export_pdf_base(
            'pdf_book_regular',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :english_regular,
            )
          )
        else
          export_pdf_base(
            'pdf_book_regular',
            options.merge(
              'include-version-control-info' => false,
              'page_settings_key' => :foreign_regular,
            )
          )
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

      def export_pdf_recording_merged(options)
        # Skip files that don't contain gap_marks
        skip_file_proc = Proc.new { |contents, filename| !contents.index('%') }
        # Merge contents of target language and primary language for interleaved
        # printing
        pre_process_content_proc = lambda { |contents, filename, options|
          primary_filename = Repositext::Utils::CorrespondingPrimaryFileFinder.find(
            filename: filename,
            language_code_3_chars: config.setting(:language_code_3_chars),
            rtfile_dir: config.base_dir(:rtfile_dir),
            relative_path_to_primary_repo: config.setting(:relative_path_to_primary_repo),
            primary_repo_lang_code: config.setting(:primary_repo_lang_code)
          )
          Kramdown::Converter::LatexRepositextRecordingMerged.custom_pre_process_content(
            contents,
            File.read(primary_filename)
          )
        }
        # Adjust latex template
        post_process_latex_proc = lambda { |latex, options|
          Kramdown::Converter::LatexRepositextRecordingMerged.custom_post_process_latex(
            latex
          )
        }
        export_pdf_base(
          'pdf_recording_merged',
          options.merge(
            skip_file_proc: skip_file_proc,
            pre_process_content_proc: pre_process_content_proc,
            post_process_latex_proc: post_process_latex_proc,
          )
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

      # @param [String] variant one of 'pdf_plain', 'pdf_recording', 'pdf_translator'
      def export_pdf_base(variant, options)
        if !export_pdf_variants.include?(variant)
          raise(ArgumentError.new("Invalid variant: #{ variant.inspect }"))
        end
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:pdf_export_dir)
        options = options.merge({
          additional_footer_text: options['additional-footer-text'],
          first_eagle_override: config.setting(:first_eagle_override, false),
          font_leading_override: config.setting(:font_leading_override, false),
          font_name_override: config.setting(:font_name_override, false),
          font_size_override: config.setting(:font_size_override, false),
          header_text: config.setting(:pdf_export_header_text),
          is_primary_repo: config.setting(:is_primary_repo),
          language_code_3_chars: config.setting(:language_code_3_chars),
          version_control_page: options['include-version-control-info'],
        })
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to #{ variant }",
          options
        ) do |contents, filename|
          options[:source_filename] = filename
          if options[:skip_file_proc] && options[:skip_file_proc].call(contents, filename)
            $stderr.puts " - Skipping #{ filename } - matches options[:skip_file_proc]"
            next([Outcome.new(true, { contents: nil })])
          end
          if options[:pre_process_content_proc]
            contents = options[:pre_process_content_proc].call(contents, filename, options)
          end
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(contents)
          kramdown_doc = Kramdown::Document.new('', options)
          kramdown_doc.root = root
          latex_converter_method = variant.sub(/\Apdf/, 'to_latex_repositext')
          latex = kramdown_doc.send(latex_converter_method)
          if options[:post_process_latex_proc]
            latex = options[:post_process_latex_proc].call(latex, options)
          end
          pdf = Repositext::Convert::LatexToPdf.convert(latex)

          [
            Outcome.new(
              true,
              {
                contents: pdf,
                extension: "#{ variant.sub(/\Apdf_/, '') }.pdf",
                output_is_binary: true,
              }
            )
          ]
        end
        # Run pdf export validation after PDFs have been exported
        validate_pdf_export(options)
      end

      # Export AT files in /content to plain kramdown (no record_marks,
      # subtitle_marks, or gap_marks)
      def export_plain_kramdown(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:plain_kramdown_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to plain kramdown",
          options
        ) do |contents, filename|
          md = convert_at_string_to_plain_markdown(contents)
          [Outcome.new(true, { contents: md, extension: '.md' })]
        end
      end


      # Export AT files in /content to plain text
      def export_plain_text(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:plain_text_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to plain text",
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
          txt = doc.send(config.kramdown_converter_method(:to_plain_text))
          [Outcome.new(true, { contents: txt, extension: 'txt' })]
        end
      end


      # Export Subtitle files
      def export_subtitle(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:subtitle_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
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
        if config.setting(:is_primary_repo)
          # We're in primary repo, copy subtitle_marker_csv_files to foreign repo
          # This works because options['output'] points to foreign repo.
          copy_subtitle_marker_csv_files_to_subtitle_export(options)
        else
          # Whe're operating on foreign repo: Export subtitles from primary
          # repo and copy them to this foreign repo's subtitle_export dir.
          # Recursively call this method with some options modified:
          # We call it via `Cli.start` so that we can use a different Rtfile.
          primary_repo_rtfile_path = File.join(config.primary_repo_base_dir, 'Rtfile')
          Repositext::Cli.start([
            "export",
            "subtitle",
            "--content-type", options['content-type'], # use same content_type
            "--file-selector", input_file_selector, # use same file-selector
            "--rtfile", primary_repo_rtfile_path, # use primary repo's Rtfile
            "--output", output_base_dir, # use this foreign repo's subtitle_export dir
          ])
        end
      end

      # Export Subtitle Tagging files
      def export_subtitle_tagging(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:subtitle_tagging_export_dir)
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to subtitle tagging",
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
          pdf_book_bound
          pdf_book_regular
          pdf_comprehensive
          pdf_plain
          pdf_recording
          pdf_recording_merged
          pdf_translator
          pdf_web
        ]
      end

    end
  end
end
