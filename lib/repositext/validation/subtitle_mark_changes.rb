class Repositext
  class Validation
    class SubtitleMarkChanges < Validation

      # Specifies validations to run for subtitle_mark_csv files in /content
      def run_list
        # Validate that there are no significant changes to subtitle_mark positions.
        # Define proc that computes subtitle_mark_csv filename from content_at filename
        stm_csv_file_name_proc = lambda { |input_filename, file_specs|
          ca_base_dir, ca_file_pattern = file_specs[:content_at_files]
          stm_csv_base_dir, stm_csv_file_pattern = file_specs[:subtitle_markers_csv_files]
            input_filename.gsub(ca_base_dir, stm_csv_base_dir)
                          .gsub(/\.at\z/, '.subtitle_markers.csv')
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, stm_csv_file_name_proc) do |ca_filename, stm_csv_filename|
          Validator::SubtitleMarkNoSignificantChanges.new(
            [ca_filename, stm_csv_filename], @logger, @reporter, @options
          ).run
        end
        # validate_files(:repositext_files) do |file_name|
        #   Validator::Utf8Encoding.new(file_name, @logger, @reporter, @options).run
        # end
      end

    end
  end
end
