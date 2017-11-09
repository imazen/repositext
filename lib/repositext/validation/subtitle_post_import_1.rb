class Repositext
  class Validation
    # Validation to run after a subtitle import 1/2.
    # This runs _before_ subtitle operations are transferred to foreign files.
    class SubtitlePostImport1 < Validation

      # Specifies validations to run after subtitle/subtitle_tagging import.
      def run_list

        # Single files

        validate_files(:content_at_files) do |content_at_file|
          Validator::KramdownSyntaxAt.new(content_at_file, @logger, @reporter, @options).run
          Validator::Utf8Encoding.new(content_at_file, @logger, @reporter, @options).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              content_at_file, @logger, @reporter, @options.merge(:content_type => :content)
            ).run
            Validator::SubtitleMarkSpacing.new(
              content_at_file, @logger, @reporter, @options
            ).run
          else
            # Foreign files
            Validator::SubtitleMarkSequenceSyntax.new(
              content_at_file, @logger, @reporter, @options
            ).run
          end
        end

        # File pairs

        # Validate that subtitle_export from new content_at is identical to
        # subtitle/subtitle_tagging import file. This is an extra safety measure
        # to make sure nothing went wrong.
        # Define proc that computes subtitle_import file from content_at file
        si_file_proc = lambda { |content_at_file|
          content_at_file.corresponding_subtitle_import_txt_file
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, si_file_proc) do |ca, sti|
          Validator::SubtitleImportConsistency.new(
            [ca, sti],
            @logger,
            @reporter,
            @options.merge(:subtitle_import_consistency_compare_mode => 'post_import')
          ).run
        end

      end

    end
  end
end
