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