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

      def export_pdf_book(options)
        export_pdf_base(
          'pdf_book',
          options.merge(
            'include-version-control-info' => false,
            'page_settings_key' => compute_pdf_export_page_settings_key(
              config.setting(:is_primary_repo),
              config.setting(:pdf_export_binding),
              'book'
            ),
          )
        )
      end

      def export_pdf_comprehensive(options)
        # Contains everything
        export_pdf_base(
          'pdf_comprehensive',
          options.merge(
            'page_settings_key' => compute_pdf_export_page_settings_key(
              config.setting(:is_primary_repo),
              config.setting(:pdf_export_binding),
              'enlarged'
            ),
          )
        )
      end

      def export_pdf_plain(options)
        # contains all formatting, no AT specific tokens
        export_pdf_base(
          'pdf_plain',
          options.merge(
            'page_settings_key' => compute_pdf_export_page_settings_key(
              config.setting(:is_primary_repo),
              config.setting(:pdf_export_binding),
              'enlarged'
            ),
          )
        )
      end

      def export_pdf_recording(options)
        # Skip files that don't contain gap_marks
        skip_file_proc = Proc.new { |contents, filename| !contents.index('%') }
        export_pdf_base(
          'pdf_recording',
          options.merge(
            :skip_file_proc => skip_file_proc,
            'page_settings_key' => compute_pdf_export_page_settings_key(
              config.setting(:is_primary_repo),
              config.setting(:pdf_export_binding),
              'enlarged'
            ),
          )
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
            content_type_dir: config.base_dir(:content_type_dir),
            relative_path_to_primary_content_type: config.setting(:relative_path_to_primary_content_type),
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
            'page_settings_key' => compute_pdf_export_page_settings_key(
              config.setting(:is_primary_repo),
              config.setting(:pdf_export_binding),
              'enlarged'
            ),
          )
        )
      end

      def export_pdf_translator(options)
        export_pdf_base(
          'pdf_translator',
          options.merge(
            'page_settings_key' => compute_pdf_export_page_settings_key(
              config.setting(:is_primary_repo),
              config.setting(:pdf_export_binding),
              'enlarged'
            ),
          )
        )
      end

      def export_pdf_web(options)
        export_pdf_base(
          'pdf_web',
          options.merge(
            'include-version-control-info' => false,
            'page_settings_key' => compute_pdf_export_page_settings_key(
              config.setting(:is_primary_repo),
              config.setting(:pdf_export_binding),
              'enlarged'
            ),
          )
        )
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
          font_leading: config.setting(:pdf_export_font_leading),
          font_name: config.setting(:pdf_export_font_name),
          font_size: config.setting(:pdf_export_font_size),
          is_primary_repo: config.setting(:is_primary_repo),
          language_code_2_chars: config.setting(:language_code_2_chars),
          language_code_3_chars: config.setting(:language_code_3_chars),
          title_font_name: config.setting(:pdf_export_title_font_name),
          version_control_page: options['include-version-control-info'],
        })
        primary_footer_titles = compute_primary_footer_titles # hash with date codes as keys and primary titles as values
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to #{ variant }",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          contents = content_at_file.contents
          filename = content_at_file.filename
          config.update_for_file(filename.gsub(/\.at\z/, '.data.json'))
          options[:footer_title_english] = primary_footer_titles[content_at_file.extract_product_identity_id(false)]
          options[:header_text] = config.setting(:pdf_export_header_text)
          options[:first_eagle] = config.setting(:pdf_export_first_eagle)
          if options[:pre_process_content_proc]
            contents = options[:pre_process_content_proc].call(contents, filename, options)
          end
          if options[:skip_file_proc] && options[:skip_file_proc].call(contents, filename)
            $stderr.puts " - Skipping #{ filename } - matches options[:skip_file_proc]"
            next([Outcome.new(true, { contents: nil })])
          end
          options[:source_filename] = filename
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


      # Export Subtitle files. Behavior depends on whether we are in
      # * English:
      #     * Export subtitle_export/61/61-0723e_0794.en.txt
      #     * Copy 61/eng61-0723e_0794.subtitle_markers.csv
      # * Foreign calls itself recursively to obtain the following:
      #     * Export subtitle_export/61/61-0723e_0794.es.txt
      #     * Export subtitle_export/61/61-0723e_0794.en.txt
      #     * Copy 61/eng61-0723e_0794.subtitle_markers.csv
      def export_subtitle(options)
        if options['file-selector'] =~ /[a-z]{3}\d{2}-\d{4}/i
          # File selector contains language code (e.g., "*spn57-0123*"). This
          # prevents foreign subtitle exports from working as we also need to
          # export the corresponding primary files, however they will never
          # be processed as they don't match the file selector.
          raise ArgumentError.new("\nPlease don't add language codes to the file selector since export may have to run on primary and foreign languages: #{ options['file-selector'].inspect }")
        end
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
        # Fork depending on whether we're in primary or foreign repo.
        # If command is initially run on primary, it will reach the primary
        # brach only. If this command was called on foreign initially, it will
        # first execute the foreign branch, then call itself recursively on
        # the primary repo and execute the primary branch.
        if config.setting(:is_primary_repo)
          # We're in primary repo, copy subtitle_marker_csv_files to foreign repo
          # This works because options['output'] points to foreign repo.
          copy_subtitle_marker_csv_files_to_subtitle_export(options)
        else
          # Whe're operating on foreign repo: Export subtitles from primary
          # repo and copy them to this foreign repo's subtitle_export dir.
          # Recursively call this method with some options modified:
          # We call it via `Cli.start` so that we can use a different Rtfile.
          primary_repo_rtfile_path = File.join(config.primary_content_type_base_dir, 'Rtfile')
          args = [
            "export",
            "subtitle",
            "--content-type-name", options['content-type-name'], # use same content_type
            "--file-selector", input_file_selector, # use same file-selector
            "--rtfile", primary_repo_rtfile_path, # use primary repo's Rtfile
            "--output", output_base_dir, # use this foreign repo's subtitle_export dir
          ]
          args << '--skip-git-up-to-date-check'  if options['skip-git-up-to-date-check']
          Repositext::Cli.start(args)
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

      # Returns the page_settings_key to use
      # @param is_primary_repo [Boolean]
      # @param binding [String] 'stitched' or 'bound'
      # @param size [String] 'book' or 'enlarged'
      # @return [Symbol], e.g., :english_stitched, or :foreign_bound
      def compute_pdf_export_page_settings_key(is_primary_repo, binding, size)
        if !%w[bound stitched].include?(binding)
          raise ArgumentError.new("Invalid binding: #{ binding.inspect }")
        end
        if !%w[book enlarged].include?(size)
          raise ArgumentError.new("Invalid size: #{ size.inspect }")
        end
        [
          (is_primary_repo ? 'english' : 'foreign'),
          (
            (!is_primary_repo && 'enlarged' == size) ? 'stitched' : binding
          ), # always use stitched for foreign enlarged
        ].join('_').to_sym
      end

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
          pdf_recording_merged
          pdf_translator
          pdf_web
        ]
      end

      # Returns a hash with English titles as values and date code as keys
      def compute_primary_footer_titles
        raise "Implement me in sub-class"
      end

    end
  end
end
