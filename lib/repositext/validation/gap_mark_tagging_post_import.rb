class Repositext
  class Validation
    # Validation to run after a gap mark tagging import.
    class GapMarkTaggingPostImport < Validation

      # Specifies validations to run after gap_mark_tagging import.
      # NOTE: md files are not affected by gap_mark_tagging import, so we don't need to validate them.
      def run_list
        # Validate that gap_mark_tagging_export from new content_at is identical to
        # gap_mark_tagging import file. This is an extra safety measure
        # to make sure nothing went wrong.
        # Define proc that computes gap_mark_tagging_import file from content_at file
        gi_file_proc = lambda { |content_at_file|
          content_at_file.corresponding_gap_mark_tagging_import_file
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, gi_file_proc) do |content_at_file, gap_mark_tagging_import_file|
          Validator::GapMarkTaggingImportConsistency.new(
            [content_at_file, gap_mark_tagging_import_file],
            @logger,
            @reporter,
            @options.merge(:gap_mark_tagging_import_consistency_compare_mode => 'post_import')
          ).run
        end

        # Validate content_at files
        validate_files(:content_at_files) do |content_at_file|
          Validator::Utf8Encoding.new(content_at_file, @logger, @reporter, @options).run
          Validator::KramdownSyntaxAt.new(
            content_at_file,
            @logger,
            @reporter,
            @options.merge(
              "validator_invalid_gap_mark_regex" => config.setting(:validator_invalid_gap_mark_regex),
              "validator_invalid_subtitle_mark_regex" => config.setting(:validator_invalid_subtitle_mark_regex)
            )
          ).run
        end
      end

    end
  end
end
