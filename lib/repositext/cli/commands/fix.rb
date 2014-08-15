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
        input_file_spec = options['input'] || 'idml_import_dir/at_files'
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.at\z/i,
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
        input_file_spec = options['input'] || 'staging_dir/at_files'
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.at\z/i,
          "Adjusting merged :record_mark positions",
          options
        ) do |contents, filename|
          outcome = Repositext::Fix::AdjustMergedRecordMarkPositions.fix(contents, filename)
          [outcome]
        end
      end

      # Converts A.M., P.M., A.D. and B.C. to lower case and wraps them in span.smcaps
      def fix_convert_abbreviations_to_lower_case(options)
        input_file_spec = options['input'] || 'staging_dir/at_files'
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.(at|pt|txt)\z/i,
          "Converting abbreviations to lower case",
          options
        ) do |contents, filename|
          outcome = Repositext::Fix::ConvertAbbreviationsToLowerCase.fix(contents, filename)
          [outcome]
        end
      end

      # Convert -- and ... and " to typographically correct characters
      def fix_convert_folio_typographical_chars(options)
        input_file_spec = options['input'] || 'folio_import_dir/at_files'
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.(at|pt|txt)\z/i,
          "Changing typographical characters in files",
          options
        ) do |contents, filename|
          outcome = Repositext::Fix::ConvertFolioTypographicalChars.fix(contents, filename)
          [outcome]
        end
      end

      def fix_normalize_editors_notes(options)
        # Don't set default file_spec since this gets called both in folio
        # and idml.
        if options['input'].nil?
          raise(ArgumentError.new("'input' option is required for this command"))
        end
        input_file_spec = options['input']
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.at\z/i,
          "Normalizing editors notes",
          options
        ) do |contents, filename|
          outcome = Repositext::Fix::NormalizeEditorsNotes.fix(contents, filename)
          [outcome]
        end
      end

      def fix_normalize_subtitle_mark_before_gap_mark_positions(options)
        # Don't set default file_spec. Needs to be provided. This could be called
        # from a number of places.
        if options['input'].nil?
          raise(ArgumentError.new("'input' option is required for this command"))
        end
        input_file_spec = options['input']
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.at\z/i,
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
        # input_file_spec = options['input'] || 'rtfile_dir/repositext_files'
        # Repositext::Cli::Utils.change_files_in_place(
        #   config.compute_glob_pattern(input_file_spec),
        #   /.\z/i,
        #   "Normalizing trailing newlines",
        #   options
        # ) do |contents, filename|
        #   [Outcome.new(true, { contents: contents.gsub(/(?<!\n)\n*\z/, "\n") }, [])]
        # end

        which_files = :all # :content_at_only or :all
        case which_files
        when :content_at_only
          base_dirs = %w[content_dir]
          file_type = 'at_files'
        when :all
          # Process all subfolders of root. Don't touch files in root.
          base_dirs = %w[
            compare_dir
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
          file_type = 'repositext_files'
        else
          raise "Invalid which_files: #{ which_files.inspect }"
        end
        base_dirs.each do |base_dir_name|
          input_file_spec = "#{ base_dir_name }/#{ file_type }"
          Repositext::Cli::Utils.change_files_in_place(
            config.compute_glob_pattern(input_file_spec),
            /.\z/i,
            "Normalizing trailing newlines in #{ base_dir_name }/#{ file_type }",
            options
          ) do |contents, filename|
            [Outcome.new(true, { contents: contents.gsub(/(?<!\n)\n*\z/, "\n") }, [])]
          end
        end
      end

      def fix_remove_underscores_inside_folio_paragraph_numbers(options)
        input_file_spec = options['input'] || 'folio_import_dir/at_files'
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(input_file_spec),
          /\.at\z/i,
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
