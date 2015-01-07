class Repositext
  class Validation
    class GapMarkTaggingPostImport < Validation

      # Specifies validations to run after gap_mark_tagging import.
      # NOTE: md files are not affected by gap_mark_tagging import, so we don't need to validate them.
      def run_list
        # Validate that gap_mark_tagging_export from new content_at is identical to
        # gap_mark_tagging import file. This is an extra safety measure
        # to make sure nothing went wrong.
        # Define proc that computes gap_mark_tagging_import filename from content_at filename
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
            @options.merge(:gap_mark_tagging_import_consistency_compare_mode => 'post_import')
          ).run
        end

        # Validate content_at files
        validate_files(:content_at_files) do |path|
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
          Validator::KramdownSyntaxAt.new(File.open(path), @logger, @reporter, @options).run
        end
      end

    end
  end
end
