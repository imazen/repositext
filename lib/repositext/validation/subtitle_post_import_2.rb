class Repositext
  class Validation
    # Validation to run after a subtitle import 2/2.
    # This runs _after_ subtitle operations have been transferred to foreign files.
    class SubtitlePostImport2 < Validation

      # Specifies validations to run after subtitle/subtitle_tagging import.
      def run_list

        # File pairs

        # Validate that subtitle_mark counts match between content_at and subtitle marker csv files
        # Define proc that computes subtitle_marker_csv filename from content_at filename
        stm_csv_file_name_proc = lambda { |input_filename, file_specs|
          Repositext::Utils::CorrespondingPrimaryFileFinder.find(
            filename: input_filename,
            language_code_3_chars: @options['primary_content_type_transform_params'][:language_code_3_chars],
            content_type_dir: @options['primary_content_type_transform_params'][:content_type_dir],
            relative_path_to_primary_content_type: @options['primary_content_type_transform_params'][:relative_path_to_primary_content_type],
            primary_repo_lang_code: @options['primary_content_type_transform_params'][:primary_repo_lang_code]
          ).gsub( # update file extension
            /\.at\z/,
            '.subtitle_markers.csv'
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, stm_csv_file_name_proc) do |ca, stm_csv|
          # skip if subtitle_markers CSV file doesn't exist
          next  if !File.exist?(stm_csv)
          Validator::SubtitleMarkCountsMatch.new(
            [File.open(ca), File.open(stm_csv)], @logger, @reporter, @options
          ).run
        end

      end

    end
  end
end
