class Repositext
  class Cli
    # This namespace contains methods related to the `fix` command (ongoing fixes).
    module Fix

    private

      # Adds initial persistent subtitle ids and record ids to
      # subtitle_marker.csv files.
      # This should only be run once on the primary repo.
      def fix_add_initial_persistent_subtitle_ids(options)
        stids_inventory_file = File.open(
          File.join(config.base_dir(:data_dir), 'subtitle_ids.txt'),
          'r+'
        )
        if stids_inventory_file.read.present?
          # We expect inventory file to be empty when we run this command
          raise ArgumentError.new("SPID inventory file is not empty!")
        end

        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :csv_extension
          ),
          options['file_filter'] || /\.subtitle_markers\.csv\z/i,
          "Adding initial persistent subtitle ids",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |stm_csv_file|
          ccafn = stm_csv_file.filename.sub('.subtitle_markers.csv', '.at')
          corresponding_content_at_file = RFile::ContentAt.new(
            File.read(ccafn),
            stm_csv_file.language,
            ccafn
          )
          outcome = Repositext::Process::Fix::AddInitialPersistentSubtitleIds.new(
            stm_csv_file,
            corresponding_content_at_file,
            stids_inventory_file
          ).fix
          [Outcome.new(outcome.success, { contents: outcome.result })]
        end
      end

      # Adds line breaks into file's text
      def fix_add_line_breaks(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_type_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :html_extension
          ),
          options['file_filter'],
          "Adjusting :gap_mark positions",
          options
        ) do |contents, filename|
          with_line_breaks = contents.gsub('</p><p>', "</p>\n<p>")
                                     .gsub('</p><blockquote>', "</p>\n<blockquote>")
                                     .gsub('</blockquote><blockquote>', "</blockquote>\n<blockquote>")
                                     .gsub('</blockquote><p>', "</blockquote>\n<p>")
          [Outcome.new(true, { contents: with_line_breaks }, [])]
        end
      end

      # Move gap_marks (%) to the outside of
      # * asterisks
      # * quotes (primary or secondary)
      # * parentheses
      # * brackets
      # Those characters may be nested, move % all the way out if those characters
      # are directly adjacent.
      # If % directly follows an elipsis, move to the front of the ellipsis
      # (unless where elipsis and % are between two words like so: word…%word)
      def fix_adjust_gap_mark_positions(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :idml_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Adjusting :gap_mark positions",
          options
        ) do |contents, filename|
          outcome = Repositext::Process::Fix::AdjustGapMarkPositions.fix(
            contents,
            filename,
            content_type.language
          )
          [outcome]
        end
      end

      # When merging AT imported from Folio XML with AT imported from IDML,
      # the :record_marks sometimes end up in the middle of a paragraph.
      # This happens when Folio and IDML have textual differences.
      # This script moves any :record_marks that are in an invalid position
      # to before the next paragraph so that they are guaranteed to be between
      # paragraphs, and that they are preceded by a blank line.
      # @param [Hash] options
      def fix_adjust_merged_record_mark_positions(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :staging_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Adjusting merged :record_mark positions",
          options
        ) do |contents, filename|
          outcome = Repositext::Process::Fix::AdjustMergedRecordMarkPositions.fix(contents, filename)
          [outcome]
        end
      end

      # Converts A.M., P.M., A.D. and B.C. to lower case and wraps them in span.smcaps
      def fix_convert_abbreviations_to_lower_case(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :staging_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Converting abbreviations to lower case",
          options
        ) do |contents, filename|
          outcome = Repositext::Process::Fix::ConvertAbbreviationsToLowerCase.fix(contents, filename)
          [outcome]
        end
      end

      # Convert -- and ... and " to typographically correct characters
      def fix_convert_folio_typographical_chars(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :folio_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Changing typographical characters in files",
          options
        ) do |contents, filename|
          outcome = Repositext::Process::Fix::ConvertFolioTypographicalChars.fix(
            contents,
            filename,
            content_type.language
          )
          [outcome]
        end
      end

      # Sets st_sync_active to false for any files not in the list of
      # sync_enabled_date_codes.
      # To use it, update the list of date codes in sync_enabled_date_codes.
      # The date codes in this list will NOT be deactivated.
      # Only date codes that exist in the current repo and are not in the list
      # will be deactivated.
      def fix_deactivate_st_sync_for_files(options)
        # Compute date codes to be deactivated
        sync_enabled_date_codes = ["53-0608a","53-0609a","53-0729","54-0103e","54-0103m","54-0509","54-0515","55-0117","55-0724","55-0731","56-0200","56-0805","57-0419","57-0818","57-0821","57-0825e","57-0825m","57-0828","57-0901e","57-0901m","57-0908e","57-0908m","57-0915e","57-0915m","57-0922e","57-0925","57-1002","57-1006","57-1222","58-0108","58-0309e","58-0720e","58-0720m","58-0927","58-0928e","58-1005e","58-1005m","58-1007","58-1012","58-1228","59-0125","59-0301m","59-0419a","59-0510m","59-0628e","59-0628m","59-0712","59-0812","59-1108","59-1216","59-1217","59-1219","59-1223","59-1227e","59-1227m","60-0221","60-0229","60-0308","60-0402","60-0515e","60-0515m","60-0518","60-0522e","60-0522m","60-0911e","60-0925","60-1002","60-1204m","60-1225","61-0112","61-0425b","61-0723e","61-0730e","61-0730m","61-0806","61-0827","61-1015e","61-1015m","61-1105","61-1119","61-1210","61-1217","61-1231e","62-0119","62-0121e","62-0123","62-0204","62-0211","62-0311","62-0401","62-0422","62-0506","62-0513e","62-0513m","62-0527","62-0531","62-0601","62-0603","62-0909m","62-1013","62-1014e","62-1014m","62-1104e","62-1104m","62-1111e","62-1209","62-1223","62-1230e","62-1230m","62-1231","63-0120e","63-0120m","63-0317e","63-0317m","63-0318","63-0319","63-0320","63-0321","63-0322","63-0323","63-0324e","63-0324m","63-0412e","63-0412m","63-0623e","63-0623m","63-0630e","63-0630m","63-0707m","63-0714e","63-0714m","63-0717","63-0728","63-0818","63-0825e","63-0825m","63-0901e","63-0901m","63-1028","63-1110e","63-1110m","63-1124e","63-1124m","63-1201x","63-1222","63-1226","63-1229e","63-1229m","64-0119","64-0121","64-0122","64-0125","64-0126","64-0205","64-0207","64-0213","64-0304","64-0305","64-0306","64-0307","64-0311","64-0321e","64-0322","64-0409","64-0410","64-0411","64-0412","64-0614e","64-0614m","64-0619","64-0620b","64-0621","64-0629","64-0705","64-0719e","64-0719m","64-0726e","64-0726m","64-0802","64-0816","64-0823e","64-0823m","64-0830e","64-0830m","64-1212","64-1221","64-1227","65-0116x","65-0118","65-0119","65-0120","65-0123","65-0124","65-0217","65-0218","65-0219","65-0220","65-0220x","65-0221e","65-0221m","65-0410","65-0418e","65-0418m","65-0424","65-0425","65-0426","65-0427","65-0429b","65-0429e","65-0711","65-0718e","65-0718m","65-0725e","65-0725m","65-0801e","65-0801m","65-0815","65-0822e","65-0822m","65-0829","65-0911","65-0919","65-1031m","65-1125","65-1126","65-1127e","65-1128e","65-1128m","65-1204","65-1205","65-1206","65-1207"]
        all_date_codes = Dir.glob(
          config.compute_glob_pattern(
            :content_dir,
            :all_files,
            :json_extension
          )
        ).map { |e|
          e.split('/').last[/\d\d-\d\d\d\d[a-z]?/]
        }
        date_codes_to_deactivate = all_date_codes - sync_enabled_date_codes

        # Deactivate date codes
        content_dir = config.compute_base_dir(:content_dir)
        puts
        puts "Setting st_sync_active to false for the following files:".color(:blue)
        date_codes_to_deactivate.each do |date_code|
          data_json_file = RFile::DataJson.find_by_date_code(
            date_code,
            '.data.json',
            content_type
          )
          puts " * #{ data_json_file.repo_relative_path }"
          data_json_file.update_settings!('st_sync_active' => false)
        end
      end

      # Set file permissions to standard permissions on all newly imported files
      def fix_import_file_permissions
        # set to 644
      end

      def fix_normalize_editors_notes(options)
        Repositext::Cli::Utils.change_files_in_place(
          # Don't set default file_spec since this gets called both in folio
          # and idml.
          config.compute_glob_pattern(
            options['base-dir'],
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Normalizing editors notes",
          options
        ) do |contents, filename|
          outcome = Repositext::Process::Fix::NormalizeEditorsNotes.fix(contents, filename)
          [outcome]
        end
      end

      def fix_normalize_subtitle_mark_before_gap_mark_positions(options)
        Repositext::Cli::Utils.change_files_in_place(
          # Don't set default file_spec. Needs to be provided. This could be called
          # from a number of places.
          config.compute_glob_pattern(
            options['base-dir'],
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Normalizing subtitle_mark before gap_mark positions.",
          options
        ) do |contents, filename|
          outcome = Repositext::Process::Fix::NormalizeSubtitleMarkBeforeGapMarkPositions.fix(contents, filename)
          [outcome]
        end
      end

      # Normalizes all text files to a single newline
      def fix_normalize_trailing_newlines(options)
        # This would use the input option, however that may not work since
        # we touch lots of directories as part of an import.
        # Repositext::Cli::Utils.change_files_in_place(
        #   config.compute_glob_pattern(
        #     options['base-dir'] || :content_type_dir,
        #     options['file-selector'] || :all_files,
        #     options['file-extension'] || :repositext_extensions
        #   ),
        #   /.\z/i,
        #   "Normalizing trailing newlines",
        #   options
        # ) do |contents, filename|
        #   [Outcome.new(true, { contents: contents.gsub(/(?<!\n)\n*\z/, "\n") }, [])]
        # end
        which_files = :all # :content_at_only, :content_files_only, or :all
        case which_files
        when :content_at_only
          input_base_dirs = %w[content_dir]
          input_file_extension_name = options['file-extension'] || :at_extension
        when :content_files_only
          input_base_dirs = %w[content_dir]
          input_file_extension_name = options['file-extension'] || :repositext_extensions
        when :all
          # Process all subfolders of root. Don't touch files in root.
          input_base_dirs = %w[
            content_dir
            docx_import_dir
            folio_import_dir
            idml_import_dir
            plain_kramdown_export_dir
            reports_dir
            subtitle_export_dir
            subtitle_import_dir
            subtitle_tagging_export_dir
            subtitle_tagging_import_dir
          ]
          input_file_extension_name = options['file-extension'] || :repositext_extensions
        else
          raise "Invalid which_files: #{ which_files.inspect }"
        end
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        # TODO: parallelize this since it's a cartesian product of 9 directories and possibly
        # hundreds of entries in --file-selector
        input_base_dirs.each do |input_base_dir_name|
          input_base_dir = config.compute_base_dir(input_base_dir_name)
          input_file_extension = config.compute_file_extension(input_file_extension_name)
          input_file_glob_pattern = [input_base_dir, input_file_selector, input_file_extension].join
          Repositext::Cli::Utils.change_files_in_place(
            input_file_glob_pattern,
            options['file_filter'],
            "Normalizing trailing newlines",
            options
          ) do |contents, filename|
            [Outcome.new(true, { contents: contents.gsub(/(?<!\n)\n*\z/, "\n") }, [])]
          end
        end
      end

      def fix_remove_underscores_inside_folio_paragraph_numbers(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :folio_import_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Removing underscores inside folio paragraph numbers",
          options
        ) do |contents, filename|
          outcome = Repositext::Process::Fix::RemoveUnderscoresInsideFolioParagraphNumbers.fix(contents, filename)
          [outcome]
        end
      end

      # Renumbers all paragraphs that contain a `*...*{: .pn}` span.
      def fix_renumber_paragraphs(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Renumbering paragraphs",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          outcome = Repositext::Process::Fix::RenumberParagraphs.fix(
            content_at_file.contents
          )
          [outcome]
        end
      end

      # Replaces invalid unicode locations according to unicode_replacement_mappings
      def fix_replace_invalid_unicode_locations(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Replacing invalid unicode locations",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          outcome = Repositext::Process::Fix::ReplaceInvalidUnicodeLocations.fix(
            content_at_file.contents
          )
          [outcome]
        end
      end

      def fix_test(options)
        # dummy method for testing
        puts 'fix_test'
      end

    end
  end
end
