# TODO: validate that there are no trailing spaces

class Repositext
  class Validation
    # Validation for content.
    class Content < Validation

      # Specifies validations to run for files in the /content directory
      def run_list

        # Single files

        validate_files(:content_at_files) do |path|
          Validator::ContentAtFilesStartWithRecordMark.new(File.open(path), @logger, @reporter, @options).run
          Validator::CorrectLineEndings.new(File.open(path), @logger, @reporter, @options).run
          Validator::EaglesConnectedToParagraph.new(File.open(path), @logger, @reporter, @options).run
          Validator::KramdownSyntaxAt.new(File.open(path), @logger, @reporter, @options).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkSpacing.new(
              File.open(path), @logger, @reporter, @options
            ).run
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              File.open(path), @logger, @reporter, @options.merge(:content_type => :content)
            ).run
          end
        end
        validate_files(:repositext_files) do |path|
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
        end

        # File pairs

        # Validate that there are no significant changes to subtitle_mark positions.
        # Define proc that computes subtitle_mark_csv filename from content_at filename
        # TODO: Should we rely on symlinks to STM CSV files instead?
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
          if @options['is_primary_repo']
            Validator::SubtitleMarkNoSignificantChanges.new(
              [File.open(ca), File.open(stm_csv)], @logger, @reporter, @options
            ).run
          end
        end
      end

    end
  end
end
