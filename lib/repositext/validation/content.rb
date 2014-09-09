class Repositext
  class Validation
    class Content < Validation

      # Specifies validations to run for files in the /content directory
      def run_list

        # Single files

        validate_files(:content_at_files) do |file_name|
          Validator::KramdownSyntaxAt.new(file_name, @logger, @reporter, @options).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkSpacing.new(file_name, @logger, @reporter, @options).run
          end
        end
        validate_files(:repositext_files) do |file_name|
          Validator::Utf8Encoding.new(file_name, @logger, @reporter, @options).run
        end

        # File pairs

        # Validate that there are no significant changes to subtitle_mark positions.
        # Define proc that computes subtitle_mark_csv filename from content_at filename
        stm_csv_file_name_proc = lambda { |input_filename, file_specs|
          input_filename.gsub( # update path
            @options['primary_repo_transforms'][:base_dir][:from],
            @options['primary_repo_transforms'][:base_dir][:to]
          ).gsub( # update language code
            /(?<=\/)#{ @options['primary_repo_transforms'][:language_code][:from] }(?=\d)/,
            @options['primary_repo_transforms'][:language_code][:to]
          ).gsub( # update file extension
            /\.at\z/,
            '.subtitle_markers.csv'
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, stm_csv_file_name_proc) do |ca_filename, stm_csv_filename|
          # skip if subtitle_markers CSV file doesn't exist
          next  if !File.exists?(stm_csv_filename)
          Validator::SubtitleMarkCountsMatch.new(
            [ca_filename, stm_csv_filename], @logger, @reporter, @options
          ).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkNoSignificantChanges.new(
              [ca_filename, stm_csv_filename], @logger, @reporter, @options
            ).run
          end
        end
      end

    end
  end
end
