class Repositext
  class Validation
    class SubtitleTaggingPostImport < Validation

      # Specifies validations to run after subtitle_tagging import.
      # NOTE: md files are not affected by subtitle_tagging_import, so we don't need to validate them.
      def run_list
        # Validate that subtitle_mark counts match between content_at and subtitle marker csv files
        # Define proc that computes subtitle_marker_csv filename from content_at filename
        sm_csv_file_name_proc = lambda { |input_filename, file_specs|
          input_filename.gsub(/\.at\z/, '.subtitle_markers.csv')
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, sm_csv_file_name_proc) do |ca_filename, sm_csv_filename|
          Validator::SubtitleMarkCountsMatch.new(
            [ca_filename, sm_csv_filename], @logger, @reporter, @options
          ).run
        end

        # Validate content_at files
        validate_files(:content_at_files) do |file_name|
          Validator::Utf8Encoding.new(file_name, @logger, @reporter, @options).run
          Validator::KramdownSyntaxAt.new(file_name, @logger, @reporter, @options).run
        end
      end

    end
  end
end
