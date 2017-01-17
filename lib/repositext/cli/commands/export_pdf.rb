class Repositext
  class Cli
    # This namespace contains methods related to the `export` command (PDF only).
    module Export

    private

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
        puts "Wrote kerning samples file to #{ file_path }"
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

      # Exports a PDF test document to make sure all our Latex customizations
      # work as expected.
      def export_pdf_test(options)
        language = Language::English.new
        font_name = ""
        source_filename = Dir.glob(
          File.join(
            config.compute_base_dir(:content_dir),
            '**/*.at'
          )
        ).first

        options = options.merge({
          additional_footer_text: nil,
          company_long_name: "Company Long Name",
          company_phone_number: "123-456-7890",
          company_short_name: "CSN",
          company_web_address: "www.thecompany.com",
          ed_and_trn_abbreviations: "ed\\.",
          first_eagle: "{\\lettrine[lines=2,lraise=0.355,findent=8.3pt,nindent=0pt]{\\textscale{0.465}}{}}",
          font_leading: 10.5,
          font_name: "V-Excelsior LT Std",
          font_size: 10,
          footer_title_english: "Footer title English",
          has_id_page: false,
          header_font_name: "V-Excelsior LT Std",
          header_text: "header text",
          header_footer_rules_present: false,
          id_address_primary_latex_1: "ID address primary 1",
          id_address_primary_latex_2: "ID address primary 2",
          id_address_secondary_latex_1: "ID address secondary 1",
          id_address_secondary_latex_2: "ID address secondary 2",
          id_address_secondary_latex_3: "ID address secondary 3",
          id_copyright_year: Time.now.year.to_s,
          id_extra_language_info: "Extra language info",
          id_recording: "ID recording",
          id_series: "ID series",
          id_title_1_font_size: 10,
          id_title_font_name: "V-Calisto-St",
          id_write_to_primary: "Write to primary",
          id_write_to_secondary: "Write to secondary",
          is_primary_repo: true,
          language: language,
          language_code_2_chars: language.code_2_chars,
          language_code_3_chars: language.code_3_chars,
          language_name: language.name,
          last_eagle_hspace: 16.5,
          page_settings_key: :english_stitched,
          paragraph_number_font_name: "V-Excelsior LT Std",
          primary_font_name: font_name,
          song_leftskip: "60.225",
          song_rightskip: "30.112",
          source_filename: source_filename,
          title_font_name: "V-Calisto-St",
          title_font_size: 22,
          title_vspace: 7.9675,
          truncated_header_title_length: 20,
          version_control_page: true,
          vspace_above_title1_required: true,
          vspace_below_title1_required: true,
        })

        root, warnings = config.kramdown_parser(:kramdown).parse(pdf_test_contents)
        kramdown_doc = Kramdown::Document.new('', options)
        kramdown_doc.root = root
        latex = kramdown_doc.send(:to_latex_repositext_book)

        pdf = Repositext::Process::Convert::LatexToPdf.convert(latex)
        file_path = File.join(
          File.expand_path('..', config.base_dir(:content_type_dir)),
          'pdf_export_test.pdf'
        )
        File.binwrite(file_path, pdf)
        puts "Wrote PDF export test file to #{ file_path }"
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

        unless options['keep-existing']
          # Delete all existing PDF exports that match file-selector.
          # If no file-selector is given, fall back to all files.
          delete_pdf_exports({ 'file-selector' => "**/*"}.merge(options))
        end

        input_base_dir = config.compute_base_dir(options['base-dir'] || :content_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:pdf_export_dir)
        primary_config = content_type.corresponding_primary_content_type.config
        # Options in this section get loaded once before the command is executed.
        # All settings down to the content_type will be considered.
        # NOTE: Put any options that should not be overridable at a file level here.
        options = options.merge({
          additional_footer_text: options['additional-footer-text'],
          company_long_name: config.setting(:company_long_name),
          company_phone_number: config.setting(:company_phone_number),
          company_short_name: config.setting(:company_short_name),
          company_web_address: config.setting(:company_web_address),
          # Contains the content for all lines of the primary address in the id.
          id_address_primary_latex_1: config.setting(:pdf_export_id_address_primary_latex_1,false),
          id_address_primary_latex_2: config.setting(:pdf_export_id_address_primary_latex_2,false),
          # Contains the content for all lines of the secondary address in the id.
          id_address_secondary_latex_1: config.setting(:pdf_export_id_address_secondary_latex_1,false),
          id_address_secondary_latex_2: config.setting(:pdf_export_id_address_secondary_latex_2,false),
          id_address_secondary_latex_3: config.setting(:pdf_export_id_address_secondary_latex_3,false),
          # Adds the text provided as a paragraph below 'RtIdParagraph'.
          id_extra_language_info: config.setting(:pdf_export_id_extra_language_info,false),
          # Sets the line spacing of the id_paragraph
          id_paragraph_line_spacing: config.setting(:pdf_export_id_paragraph_line_spacing,false),
          # Adds write to instructions above the primary address.
          id_write_to_primary: config.setting(:pdf_export_id_write_to_primary,false),
          # Adds write to instructions above the secondary address.
          id_write_to_secondary: config.setting(:pdf_export_id_write_to_secondary,false),
          is_primary_repo: config.setting(:is_primary_repo),
          language: content_type.language,
          # TODO: the next three options can be derived from :language
          language_code_2_chars: config.setting(:language_code_2_chars),
          language_code_3_chars: config.setting(:language_code_3_chars),
          language_name: content_type.language.name,
          # NOTE: We grab pdf_export_font_name from the _PRIMARY_ repo's config
          primary_font_name: primary_config.setting(:pdf_export_font_name),
          # Do not move the 'song_leftskip' and 'song_rightskip' settings to the file specific settings.
          # We do not want to set these at a file level.
          # This sets the right and left margin for 'RtSong', 'RtSongBreak' and 'RtStanza'.
          song_leftskip: config.setting(:pdf_export_song_leftskip),
          song_rightskip: config.setting(:pdf_export_song_rightskip),
          # Sets whether a languge is read left to right.
          text_left_to_right: config.setting(:pdf_export_text_left_to_right),
          # Sets the vbadness_penalty limit for veritcal justification. This is the maximum penalty allowed.
          vbadness_penalty: config.setting(:pdf_export_vbadness_penalty),
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
          # Options in this section get updated on a per-file basis.
          options[:ed_and_trn_abbreviations] = config.setting(:pdf_export_ed_and_trn_abbreviations)
          options[:first_eagle] = config.setting(:pdf_export_first_eagle)
          # Sets the starting page number.
          options[:first_page_number] = config.setting(:pdf_export_first_page_number)
          options[:font_leading] = config.setting(:pdf_export_font_leading)
          options[:font_name] = config.setting(:pdf_export_font_name)
          options[:font_size] = config.setting(:pdf_export_font_size)
          options[:footer_title_english] = primary_titles[content_at_file.extract_product_identity_id(false)]
          options[:has_id_page] = config.setting(:pdf_export_has_id_page)
          options[:header_font_name] = config.setting(:pdf_export_header_font_name)
          options[:header_footer_rules_present] = config.setting(:pdf_export_header_footer_rules_present)
          options[:header_superscript_raise] = config.setting(:pdf_export_header_superscript_raise)
          options[:header_superscript_scale] = config.setting(:pdf_export_header_superscript_scale)
          options[:header_text] = config.setting(:pdf_export_header_text)
          options[:hrule_latex] = config.setting(:pdf_export_hrule_latex)
          options[:id_copyright_year] = config.setting(:erp_id_copyright_year, false)
          options[:id_recording] = config.setting(:pdf_export_id_recording, false)
          options[:id_series] = config.setting(:pdf_export_id_series, false)
          options[:id_title_1_font_size] = config.setting(:pdf_export_id_title_1_font_size, false)
          options[:id_title_1_superscript_raise] = config.setting(:pdf_export_id_title_1_superscript_raise)
          options[:id_title_1_superscript_scale] = config.setting(:pdf_export_id_title_1_superscript_scale)
          options[:id_title_font_name] = config.setting(:pdf_export_id_title_font_name, false)
          options[:last_eagle_hspace] = config.setting(:pdf_export_last_eagle_hspace)
          options[:page_settings_key] = compute_pdf_export_page_settings_key(
            config.setting(:pdf_export_page_settings_key_override, false),
            config.setting(:is_primary_repo),
            pdf_export_binding,
            options['pdf_export_size']
          )
          options[:paragraph_number_font_name] = config.setting(:pdf_export_paragraph_number_font_name)
          options[:question1_indent] = config.setting(:pdf_export_question1_indent)
          options[:question2_indent] = config.setting(:pdf_export_question2_indent)
          options[:question3_indent] = config.setting(:pdf_export_question3_indent)
          options[:source_filename] = filename
          options[:title_font_name] = config.setting(:pdf_export_title_font_name)
          options[:title_font_size] = config.setting(:pdf_export_title_font_size)
          options[:title_superscript_raise] = config.setting(:pdf_export_title_superscript_raise)
          options[:title_superscript_scale] = config.setting(:pdf_export_title_superscript_scale)
          options[:title_vspace] = config.setting(:pdf_export_title_vspace)
          options[:truncated_header_title_length] = config.setting(:pdf_export_truncated_header_title_length, false)
          options[:vspace_above_title1_required] = config.setting(:pdf_export_vspace_above_title1_required)
          options[:vspace_below_title1_required] = config.setting(:pdf_export_vspace_below_title1_required)
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

        if config.setting(:pdf_export_skip_validation)
          $stderr.puts "Skipping PDF export validation for all files"
        else
          validate_pdf_export(options)
        end

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

      def pdf_test_contents
        %(^^^ {: .rid #rid-12345678}

# *The Title*{: .italic .smcaps}

^^^ {: .rid #rid-12345679}

@% This is the first paragraph.
{: .first_par .normal}

@*2*{: .pn} This is the second paragraph.
{: .normal_pn}
)
      end

    end
  end
end
