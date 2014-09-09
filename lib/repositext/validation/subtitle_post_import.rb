class Repositext
  class Validation
    class SubtitlePostImport < Validation

      # Specifies validations to run after subtitle/subtitle_tagging import.
      def run_list

        # Single files

        validate_files(:content_at_files) do |filename|
          Validator::KramdownSyntaxAt.new(filename, @logger, @reporter, @options).run
          Validator::Utf8Encoding.new(filename, @logger, @reporter, @options).run
          if @options['is_primary_repo']
            Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
              filename, @logger, @reporter, @options.merge(:content_type => :content)
            ).run
            Validator::SubtitleMarkSpacing.new(filename, @logger, @reporter, @options).run
          end
        end

        # File pairs

        # Validate that subtitle_export from new content_at is identical to
        # subtitle/subtitle_tagging import file. This is an extra safety measure
        # to make sure nothing went wrong.
        # Define proc that computes subtitle_import filename from content_at filename
        si_filename_proc = lambda { |input_filename, file_specs|
          ca_base_dir, ca_file_pattern = file_specs[:content_at_files]
          si_base_dir, si_file_pattern = file_specs[:subtitle_import_files]
          Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_import(
            input_filename.gsub(ca_base_dir, si_base_dir)
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, si_filename_proc) do |ca_filename, si_filename|
          Validator::SubtitleImportConsistency.new(
            [ca_filename, si_filename],
            @logger,
            @reporter,
            @options.merge(:subtitle_import_consistency_compare_mode => 'post_import')
          ).run
        end

        # Validate that subtitle_mark counts match between content_at and subtitle marker csv files
        # Define proc that computes subtitle_marker_csv filename from content_at filename
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
        end

      end

    end
  end
end
