class Repositext
  class Validation
    # Validation to run before a gap mark tagging import.
    class GapMarkTaggingPreImport < Validation

      # Specifies validations to run before gap_mark_tagging_import.
      def run_list
        # Single files

        # Validate that every paragraph in the import file begins with a subtitle_mark
        validate_files(:gap_mark_tagging_import_files) do |gap_mark_tagging_import_file|
          Validator::Utf8Encoding.new(
            gap_mark_tagging_import_file, @logger, @reporter, @options
          ).run
        end

        # Validate that the gap_mark_tagging import still matches content_at
        # Define proc that computes gap_mark_tagging import filename from content_at filename
        gi_file_proc = lambda { |content_at_file|
          content_at_file.corresponding_gap_mark_tagging_import_file
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, gi_file_proc) do |content_at_file, gap_mark_tagging_import_file|
          Validator::GapMarkTaggingImportConsistency.new(
            [content_at_file, gap_mark_tagging_import_file],
            @logger,
            @reporter,
            @options.merge(:gap_mark_tagging_import_consistency_compare_mode => 'pre_import')
          ).run
        end

        # # TODO: compare number of gap_marks to that of corresponding file in primary repo
        # if @options[:compare_gap_mark_count_with]
        #   Validator::GapMarkTaggingImportConsistency.new(
        #     [
        #       StringIO.new(@options[:compare_gap_mark_count_with]),
        #       File.open(gi)
        #     ],
        #     @logger,
        #     @reporter,
        #     @options.merge(:gap_mark_tagging_import_consistency_compare_mode => 'pre_import')
        #   ).run
        # end

      end

    end
  end
end
