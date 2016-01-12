class Repositext
  class Validation
    class GapMarkTaggingPreImport < Validation

      # Specifies validations to run before gap_mark_tagging_import.
      def run_list
        # Single files

        # Validate that every paragraph in the import file begins with a subtitle_mark
        validate_files(:gap_mark_tagging_import_files) do |path|
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
        end

        # Validate that the gap_mark_tagging import still matches content_at
        # Define proc that computes gap_mark_tagging import filename from content_at filename
        gi_file_name_proc = lambda { |input_filename, file_specs|
          ca_base_dir = file_specs[:content_at_files].first
          gi_base_dir = file_specs[:gap_mark_tagging_import_files].first
          input_filename.gsub(ca_base_dir, gi_base_dir)
                        .gsub(/\.at\z/, '.gap_mark_tagging.txt')
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, gi_file_name_proc) do |ca, gi|
          Validator::GapMarkTaggingImportConsistency.new(
            [File.open(ca), File.open(gi)],
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
