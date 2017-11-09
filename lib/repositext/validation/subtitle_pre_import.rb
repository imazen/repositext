class Repositext
  class Validation
    # Validation to run before a subtitle import.
    class SubtitlePreImport < Validation

      # Specifies validations to run before subtitle/subtitle_tagging import.
      def run_list

        # Single files

        # Validate that every paragraph in the import file begins with a subtitle_mark
        validate_files(:subtitle_import_files) do |content_at_file|
          Validator::Utf8Encoding.new(content_at_file, @logger, @reporter, @options).run
          if content_at_file.filename.index('markers.')
            # validate all markers files
            Validator::SubtitleImportMarkersSyntax.new(
              content_at_file, @logger, @reporter, @options
            ).run
          elsif @options['is_primary_repo']
            # validate primary content AT files
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              content_at_file, @logger, @reporter, @options.merge(:content_type => :import)
            ).run
            Validator::SubtitleMarkNotFollowedBySpace.new(
              content_at_file, @logger, @reporter, @options
            )
          end
        end

        # File pairs

        # TODO: This section iterates over all content_at_files and then tries
        # to find the corresponding subtitle import files. This breaks if the
        # command is used without a file-selector and encounters a content at
        # file for which no corresponding subtitle import file exists.
        # The approach should be the other way around: Start with the subtitle
        # import files and find the corresponding content_at file.

        # Validate that the subtitle/subtitle_tagging import still matches content_at
        # Define proc that computes subtitle/subtitle_tagging import file from content_at file
        si_file_proc = lambda { |content_at_file|
          content_at_file.corresponding_subtitle_import_txt_file
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, si_file_proc) do |ca, sti|
          Validator::SubtitleImportConsistency.new(
            [ca, sti],
            @logger,
            @reporter,
            @options.merge(:subtitle_import_consistency_compare_mode => 'pre_import')
          ).run
        end

      end

    end
  end
end
