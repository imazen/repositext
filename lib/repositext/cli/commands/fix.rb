class Repositext
  class Cli
    module Fix

    private

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
          outcome = Repositext::Fix::AdjustGapMarkPositions.fix(contents, filename)
          [outcome]
        end
      end

      # When merging AT imported from Folio XML with AT imported from IDML,
      # the :record_marks sometimes end up in the middle of a paragraph.
      # This happens when Folio and IDML have textual differences.
      # This script moves any :record_marks that are in an invalid position
      # to before the next paragraph so that they are guaranteed to be between
      # paragraphs, and that they are preceded by a blank line.
      # @param[Hash] options
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
          outcome = Repositext::Fix::AdjustMergedRecordMarkPositions.fix(contents, filename)
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
          outcome = Repositext::Fix::ConvertAbbreviationsToLowerCase.fix(contents, filename)
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
          outcome = Repositext::Fix::ConvertFolioTypographicalChars.fix(contents, filename)
          [outcome]
        end
      end

      # Set file permissions to standard permissions on all newly imported files
      def fix_import_file_permissions
        set to 644
      end

      # Insert a record_mark into each content AT file that doesn't contain one
      # already
      def fix_insert_record_mark_into_all_at_files(options)
        repo_base_dir = config.base_dir(:rtfile_dir)
        primary_repo_base_dir = File.expand_path(
          config.setting(:relative_path_to_primary_repo),
          repo_base_dir
        ) + '/'
        # lambda that converts filename to corresponding filename in primary repo
        # Default option works when working on content AT files.
        filename_proc = (
          options['filename_proc'] || lambda { |filename|
            filename.gsub(
              repo_base_dir,
              primary_repo_base_dir
            ).gsub(
              /\/#{ config.setting(:language_code_3_chars) }/,
              "/#{ config.setting(:primary_repo_lang_code) }"
            )
          }
        )
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Inserting record_marks into AT files",
          options
        ) do |contents, filename|
          corresponding_primary_filename = filename_proc.call(filename)
          outcome = Repositext::Fix::InsertRecordMarkIntoAllAtFiles.fix(
            contents,
            filename,
            corresponding_primary_filename
          )
          [outcome]
        end
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
          outcome = Repositext::Fix::NormalizeEditorsNotes.fix(contents, filename)
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
          outcome = Repositext::Fix::NormalizeSubtitleMarkBeforeGapMarkPositions.fix(contents, filename)
          [outcome]
        end
      end

      # Normalizes all text files to a single newline
      def fix_normalize_trailing_newlines(options)
        # This would use the input option, however that may not work since
        # we touch lots of directories as part of an import.
        # Repositext::Cli::Utils.change_files_in_place(
        #   config.compute_glob_pattern(
        #     options['base-dir'] || :rtfile_dir,
        #     options['file-selector'] || :all_files,
        #     options['file-extension'] || :repositext_extensions
        #   ),
        #   /.\z/i,
        #   "Normalizing trailing newlines",
        #   options
        # ) do |contents, filename|
        #   [Outcome.new(true, { contents: contents.gsub(/(?<!\n)\n*\z/, "\n") }, [])]
        # end

        which_files = :all # :content_at_only or :all
        case which_files
        when :content_at_only
          input_base_dirs = %w[content_dir]
          input_file_extension_name = options['file-extension'] || :at_extension
        when :all
          # Process all subfolders of root. Don't touch files in root.
          input_base_dirs = %w[
            content_dir
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
        input_base_dirs.each do |input_base_dir_name|
          input_base_dir = config.compute_base_dir(input_base_dir_name)
          input_file_extension = config.compute_file_extension(input_file_extension_name)
          input_file_glob_pattern = [input_base_dir, input_file_selector, input_file_extension].join
          Repositext::Cli::Utils.change_files_in_place(
            input_file_glob_pattern,
            options['file_filter'],
            "Normalizing trailing newlines in #{ input_file_glob_pattern }",
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
          outcome = Repositext::Fix::RemoveUnderscoresInsideFolioParagraphNumbers.fix(contents, filename)
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
