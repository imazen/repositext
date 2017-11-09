class Repositext
  class Validation
    # Validation to make sure that no subtitle marks were moved significantly.
    class SubtitleMarkNoSignificantChanges < Validation

      # Specifies validations to run for files in the /content directory
      def run_list

        # File pairs

        # Validate that there are no significant changes to subtitle_mark positions.
        # Define proc that computes subtitle_mark_csv filename from content_at filename
        stm_csv_file_proc = lambda { |content_at_file|
          content_at_file.corresponding_subtitle_markers_csv_file
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, stm_csv_file_proc) do |ca, stm_csv|
          # skip if subtitle_markers CSV file doesn't exist
          next  if stm_csv.nil?
          Validator::SubtitleMarkNoSignificantChanges.new(
            [ca, stm_csv], @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
