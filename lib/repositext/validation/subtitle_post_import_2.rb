class Repositext
  class Validation
    # Validation to run after a subtitle import 2/2.
    # This runs _after_ subtitle operations have been transferred to foreign files.
    class SubtitlePostImport2 < Validation

      # Specifies validations to run after subtitle/subtitle_tagging import.
      def run_list

        # Single files

        validate_files(:content_at_files) do |content_at_file|
          Validator::SubtitleMarkSyntax.new(
            content_at_file, @logger, @reporter, @options.merge(:content_type => :content)
          ).run
        end

        # File pairs

        # Validate that subtitle_mark counts match between content_at and subtitle marker csv files
        # Define proc that computes subtitle_marker_csv file from content_at file
        stm_csv_file_proc = lambda { |content_at_file|
          content_at_file.corresponding_subtitle_markers_csv_file
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, stm_csv_file_proc) do |ca, stm_csv|
          # skip if subtitle_markers CSV file doesn't exist
          next  stm_csv.nil?
          Validator::SubtitleMarkCountsMatch.new(
            [ca, stm_csv], @logger, @reporter, @options
          ).run
        end

      end

    end
  end
end
