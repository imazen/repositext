class Repositext
  class Validation
    # Validation to run after a subtitle import.
    class SubtitlePostImport < Validation

      # Specifies validations to run after subtitle/subtitle_tagging import.
      def run_list

        # Single files

        validate_files(:content_at_files) do |path|
          Validator::KramdownSyntaxAt.new(File.open(path), @logger, @reporter, @options).run
          Validator::Utf8Encoding.new(File.open(path), @logger, @reporter, @options).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              File.open(path), @logger, @reporter, @options.merge(:content_type => :content)
            ).run
            Validator::SubtitleMarkSpacing.new(File.open(path), @logger, @reporter, @options).run
          end
        end

        # File pairs

        # Validate that subtitle_export from new content_at is identical to
        # subtitle/subtitle_tagging import file. This is an extra safety measure
        # to make sure nothing went wrong.
        # Define proc that computes subtitle_import filename from content_at filename
        si_filename_proc = lambda { |input_filename, file_specs|
          ca_base_dir = file_specs[:content_at_files].first
          si_base_dir = file_specs[:subtitle_import_files].first
          Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_import(
            input_filename.gsub(ca_base_dir, si_base_dir)
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, si_filename_proc) do |ca, sti|
          Validator::SubtitleImportConsistency.new(
            [File.open(ca), File.open(sti)],
            @logger,
            @reporter,
            @options.merge(:subtitle_import_consistency_compare_mode => 'post_import')
          ).run
        end

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
          next  if !File.exists?(stm_csv)
          Validator::SubtitleMarkCountsMatch.new(
            [File.open(ca), File.open(stm_csv)], @logger, @reporter, @options
          ).run
        end

      end

    end
  end
end
