class Repositext
  class Cli
    # This namespace contains methods related to the export command.
    module Export

    private

      # Export AT files in `/content` for Gap mark tagging.
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
          outcome = Repositext::Process::Export::GapMarkTagging.export(contents)
          if outcome.success?
            [Outcome.new(true, { contents: outcome.result, extension: 'gap_mark_tagging.txt' })]
          else
            outcome
          end
        end
      end

      # Export AT files in `/content` to ICML.
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

      # Export AT files in `/content` to PDF agapao variant.
      def export_pdf_agapao(options)
        export_pdf_base(
          'pdf_translator',
          options.merge(
            primary_titles_override:{
              "7777" => "AGAPAO TOUR VIDEO",
            },
            'pdf_export_size' => 'enlarged',
          )
        )
      end

      # Export AT files in `/content` to all PDF variants.
      def export_pdf_all(options)
        export_pdf_variants.each do |variant|
          self.send("export_#{ variant }", options)
        end
      end

      # Export AT files in `/content` to PDF book variant.
      def export_pdf_book(options)
        export_pdf_base(
          'pdf_book',
          options.merge(
            'include-version-control-info' => false,
            'pdf_export_size' => 'book',
          )
        )
      end

      # Export AT files in `/content` to PDF comprehensive variant.
      def export_pdf_comprehensive(options)
        # Contains everything
        export_pdf_base(
          'pdf_comprehensive',
          options.merge(
            'pdf_export_size' => 'enlarged',
          )
        )
      end

      # Export a PDF with text samples of all kerning pairs.
      # The file is exported to the current language repo's root as
      # kerning_samples.pdf
      def export_pdf_kerning_samples(options)
        latex = Kramdown::Converter::LatexRepositext::SmallcapsKerningMap.kerning_sample_latex
        pdf = Repositext::Process::Convert::LatexToPdf.convert(latex)
        file_path = File.join(
          File.expand_path('..', config.base_dir(:content_type_dir)),
          'kerning_samples.pdf'
        )
        File.binwrite(file_path, pdf)
      end

      # Export AT files in `/content` to PDF plain variant.
      def export_pdf_plain(options)
        # contains all formatting, no AT specific tokens
        export_pdf_base(
          'pdf_plain',
          options.merge(
            'pdf_export_size' => 'enlarged',
          )
        )
      end

      # Export AT files in `/content` to PDF recording variant.
      def export_pdf_recording(options)
        # Skip files that don't contain gap_marks
        skip_file_proc = Proc.new { |contents, filename| !contents.index('%') }
        export_pdf_base(
          'pdf_recording',
          options.merge(
            add_title_to_filename: true,
            include_id_recording: true,
            rename_file_extension_filter: '.recording-{stitched,bound}.pdf',
            skip_file_proc: skip_file_proc,
            'pdf_export_size' => 'enlarged',
          )
        )
      end

      # Export AT files in `/content` to PDF recording merged (bilingual) variant.
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
            add_title_to_filename: true,
            include_id_recording: true,
            rename_file_extension_filter: '.recording_merged-{stitched,bound}.pdf',
            skip_file_proc: skip_file_proc,
            pre_process_content_proc: pre_process_content_proc,
            post_process_latex_proc: post_process_latex_proc,
            'pdf_export_size' => 'enlarged',
          )
        )
      end

      # Export AT files in `/content` to PDF translator variant.
      def export_pdf_translator(options)
        export_pdf_base(
          'pdf_translator',
          options.merge(
            include_id_recording: true,
            'pdf_export_size' => 'enlarged',
          )
        )
      end

      # Export AT files in `/content` to PDF web variant.
      def export_pdf_web(options)
        export_pdf_base(
          'pdf_web',
          options.merge(
            'include-version-control-info' => false,
            'pdf_export_size' => 'book',
          )
        )
      end

      # Shared code for all PDF variants.
      # @param [String] variant one of 'pdf_plain', 'pdf_recording', 'pdf_translator'
      def export_pdf_base(variant, options)
        if !export_pdf_variants.include?(variant)
          raise(ArgumentError.new("Invalid variant: #{ variant.inspect }"))
        end
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:pdf_export_dir)
        primary_config = content_type.corresponding_primary_content_type.config
        options = options.merge({
          additional_footer_text: options['additional-footer-text'],
          company_long_name: config.setting(:company_long_name),
          company_phone_number: config.setting(:company_phone_number),
          company_short_name: config.setting(:company_short_name),
          company_web_address: config.setting(:company_web_address),
          id_address_primary_latex_1: config.setting(:pdf_export_id_address_primary_latex_1,false),
          id_address_primary_latex_2: config.setting(:pdf_export_id_address_primary_latex_2,false),
          id_address_secondary_latex_1: config.setting(:pdf_export_id_address_secondary_latex_1,false),
          id_address_secondary_latex_2: config.setting(:pdf_export_id_address_secondary_latex_2,false),
          id_address_secondary_latex_3: config.setting(:pdf_export_id_address_secondary_latex_3,false),
          id_extra_language_info: config.setting(:pdf_export_id_extra_language_info,false),
          id_write_to_primary: config.setting(:pdf_export_id_write_to_primary,false),
          id_write_to_secondary: config.setting(:pdf_export_id_write_to_secondary,false),
          is_primary_repo: config.setting(:is_primary_repo),
          language: content_type.language,
          language_code_2_chars: config.setting(:language_code_2_chars),
          language_code_3_chars: config.setting(:language_code_3_chars),
          language_name: content_type.language.name,
          paragraph_number_font_name: config.setting(:pdf_export_paragraph_number_font_name),
          # NOTE: We grab pdf_export_font_name from the _PRIMARY_ repo's config
          primary_font_name: primary_config.setting(:pdf_export_font_name),
          version_control_page: options['include-version-control-info'],
        })
        primary_titles = options[:primary_titles_override] || compute_primary_titles # hash with product indentity ids as keys and primary titles as values
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
          pdf_export_binding = config.setting(:pdf_export_binding)
          options[:ed_and_trn_abbreviations] = config.setting(:pdf_export_ed_and_trn_abbreviations)
          options[:first_eagle] = config.setting(:pdf_export_first_eagle)
          options[:font_leading] = config.setting(:pdf_export_font_leading)
          options[:font_name] = config.setting(:pdf_export_font_name)
          options[:font_size] = config.setting(:pdf_export_font_size)
          options[:footer_title_english] = primary_titles[content_at_file.extract_product_identity_id(false)]
          options[:header_font_name] = config.setting(:pdf_export_header_font_name)
          options[:header_text] = config.setting(:pdf_export_header_text)
          options[:hrules_present] = config.setting(:pdf_export_hrules_present)
          options[:id_copyright_year] = config.setting(:erp_id_copyright_year, false)
          options[:id_recording] = config.setting(:pdf_export_id_recording, false)
          options[:id_series] = config.setting(:pdf_export_id_series, false)
          options[:id_title_1_font_size] = config.setting(:pdf_export_id_title_1_font_size, false)
          options[:id_title_font_name] = config.setting(:pdf_export_id_title_font_name, false)
          options[:is_id_page_needed] = config.setting(:pdf_export_is_id_page_needed)
          options[:last_eagle_hspace] =config.setting(:pdf_export_last_eagle_hspace)
          options[:page_settings_key] = compute_pdf_export_page_settings_key(
            config.setting(:pdf_export_page_settings_key_override, false)
            config.setting(:is_primary_repo),
            pdf_export_binding,
            options['pdf_export_size']
          )
          options[:source_filename] = filename
          options[:title_font_name] = config.setting(:pdf_export_title_font_name)
          options[:title_font_size] = config.setting(:pdf_export_title_font_size)
          options[:title_vspace] = config.setting(:pdf_export_title_vspace)
          options[:truncated_header_title_length] = config.setting(:pdf_export_truncated_header_title_length, false)
          if options[:pre_process_content_proc]
            contents = options[:pre_process_content_proc].call(contents, filename, options)
          end
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
          kramdown_doc = Kramdown::Document.new('', options)
          kramdown_doc.root = root
          latex_converter_method = variant.sub(/\Apdf/, 'to_latex_repositext')
          latex = kramdown_doc.send(latex_converter_method)
          if options[:post_process_latex_proc]
            latex = options[:post_process_latex_proc].call(latex, options)
          end
          pdf = Repositext::Process::Convert::LatexToPdf.convert(latex)

          [
            Outcome.new(
              true,
              {
                contents: pdf,
                extension: "#{ variant.sub(/\Apdf_/, '') }-#{ pdf_export_binding }.pdf",
                output_is_binary: true,
              }
            )
          ]
        end
        # Run pdf export validation after PDFs have been exported
        validate_pdf_export(options)

        # Add title to filename after validations have run (validations require
        # conventional filenames)
        if options[:add_title_to_filename]
          sanitized_primary_titles = primary_titles.inject({}) { |m, (pid, title)|
            # sanitize titles: remove anything other than letters or numbers,
            # collapse whitespace and replace with underscore.
            # We also zero pad product_identity_ids to 4 digits.
            m[pid.rjust(4, '0')] = title.downcase
                          .strip
                          .gsub(/[^a-z\d\s]/, '')
                          .gsub(/\s+/, '_')
            m
          }
          file_rename_proc = Proc.new { |input_filename|
            r_file_stub = RFile::Content.new('_', Language.new, input_filename)
            product_identity_id = r_file_stub.extract_product_identity_id
            title = sanitized_primary_titles[product_identity_id]
            # insert title into filename
            # Regex contains negative lookahead to make sure product identity id
            # is not followed by title already to avoid duplicate insertion of titles
            input_filename.sub(
              /_#{ product_identity_id }\.(?!\-\-)/,
              "_#{ product_identity_id }.--#{ title }--.",
            )
          }
          distribute_add_title_to_filename(
            {
              :input_base_dir => config.compute_base_dir(:pdf_export_dir),
              :input_file_selector => config.compute_file_selector(options['file-selector'] || :all_files),
              :input_file_extension => options[:rename_file_extension_filter],
              :file_rename_proc => file_rename_proc,
              'file_filter' => options['file_filter'] || /\A((?!.--).)*\z/, # doesn't contain title already
            }
          )
        end
      end

      # Export AT files in `/content` to plain kramdown (no record_marks,
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


      # Export AT files in `/content` to plain text
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
        primary_repo = content_type.corresponding_primary_content_type.repository
        st_sync_commit_sha1 = primary_repo.read_repo_level_data['st_sync_commit']
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to subtitle",
          options.merge(
            output_path_lambda: lambda { |input_filename, output_file_attrs|
              Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_export(
                input_filename.gsub(input_base_dir, output_base_dir),
                output_file_attrs
              )
            },
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          use_subtitle_sync_behavior = false
          if use_subtitle_sync_behavior
            # sync-subtitles behavior
            # Make sure primary file (or foreign file's corresponding primary file)
            # does not require a subtitle sync.
            self_or_corresponding_primary_file = content_at_file.corresponding_primary_file
            if self_or_corresponding_primary_file.read_file_level_data['st_sync_required']
              raise "Cannot export #{ content_at_file.filename } since it requires a subtitle sync!".color(:red)
            end
          end
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = config.kramdown_parser(:kramdown).parse(content_at_file.contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          subtitle = doc.send(config.kramdown_converter_method(:to_subtitle))
          if use_subtitle_sync_behavior
            # Foreign files only: Record sync commit at which subtitles were exported
            if !config.setting(:is_primary_repo)
              content_at_file.update_file_level_data(
                'exported_subtitles_at_st_sync_commit' => st_sync_commit_sha1
              )
            end
          end
          # Return Outcome
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

      # Export test files for st-ops extraction end-to-end test:
      # We apply an st-ops file's operations to the `from` plain text with
      # subtitles and expect the outcome to be identical to the `to` plain text
      # with subtitles. This applies previously extracted subtitle operations
      # to the repo. The following files are required for this test:
      #
      # * Plain text versions (with subtitles) of all files at both `from` and `to` git commit.
      # * All subtitle marker CSV files at `from` git commit (to be able to address subtitles by stids)
      # * A single st-ops file for `from` and `to` git commits.
      #
      # Steps to prepare the files:
      #
      # * Create staging area directory, name it:
      #   `st_ops_extraction_test_files-<from_git_commit>-to-<to_git_commit>`
      # * Produce `from` version
      #     * git checkout <from_git_commit>
      #     * empty the `subtitle_export` directory
      #     * run this command `rt export subtitle_for_st_ops_extraction_test -g`
      #     * take entire `subtitle_export` directory, rename to
      #       `plain_text_and_stm_csv_files-<from_git_commit> and store in
      #       staging area.
      #     * discard all changes to repo in git.
      # * Produce `to` version
      #     * repeat steps in `from` version, replace <from_git_commit> with
      #       <to_git_commit>
      # * Add st-ops file to the staging area
      # * ZIP compress the entire staging area
      def export_subtitle_for_st_ops_extraction_test(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:subtitle_export_dir)
        primary_repo = content_type.corresponding_primary_content_type.repository
        Repositext::Cli::Utils.export_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Exporting AT files to subtitle for st-ops test",
          options.merge(
            output_path_lambda: lambda { |input_filename, output_file_attrs|
              Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_export(
                input_filename.gsub(input_base_dir, output_base_dir),
                output_file_attrs
              )
            },
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          root, warnings = config.kramdown_parser(:kramdown).parse(content_at_file.contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          subtitle_export_text = doc.send(config.kramdown_converter_method(:to_subtitle))
          # Prepare text for st-ops testing
          processed_txt = subtitle_export_text.lines.map { |e|
            next []  if e !~ /\A@/
            next []  if '' == e.strip
            e.sub!(/\A@\d+\s{4}(?!\s)(.*)/, '@\1') # remove paragraph numbers
            e
          }.flatten.join("\n")

          # Return Outcome
          [Outcome.new(true, { contents: processed_txt, extension: 'txt' })]
        end
        copy_subtitle_marker_csv_files_to_subtitle_export(options)
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
      # @param page_settings_key_override [Symbol, String, nil]
      # @param is_primary_repo [Boolean]
      # @param binding [String] 'stitched' or 'bound'
      # @param size [String] 'book' or 'enlarged'
      # @return [Symbol], e.g., :english_stitched, or :foreign_bound
      def compute_pdf_export_page_settings_key(page_settings_key_override, is_primary_repo, binding, size)
        if '' != page_settings_key_override.to_s.strip
          # santize override and return it
          return page_settings_key_override.to_sym
        end
        if !%w[bound stitched].include?(binding)
          raise ArgumentError.new("Invalid binding: #{ binding.inspect }")
        end
        if !%w[book enlarged].include?(size)
          raise ArgumentError.new("Invalid size: #{ size.inspect }")
        end
        # Always use stitched for foreign enlarged.
        # We need to support 'english_bound' because English text box is
        # different between stitched and bound.
        [
          (is_primary_repo ? 'english' : 'foreign'),
          (
            (!is_primary_repo && 'enlarged' == size) ? 'stitched' : binding
          ),
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
      def compute_primary_titles
        raise "Implement me in sub-class"
      end

    end
  end
end
