class Repositext
  class Validation
    class SubtitlePostImport < Validation

      # Specifies validations to run after subtitle/subtitle_tagging import.
      # NOTE: md files are not affected by subtitle/subtitle_tagging import, so we don't need to validate them.
      def run_list
        # Validate that subtitle_mark counts match between content_at and subtitle marker csv files
        # Define proc that computes subtitle_marker_csv filename from content_at filename
        sm_csv_filename_proc = lambda { |input_filename, file_specs|
          input_filename.gsub(/\.at\z/, '.subtitle_markers.csv')
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, sm_csv_filename_proc) do |ca_filename, sm_csv_filename|
          Validator::SubtitleMarkCountsMatch.new(
            [ca_filename, sm_csv_filename], @logger, @reporter, @options
          ).run
        end

        # Validate subtitle_mark spacing
        validate_files(:content_at_files) do |filename|
          Validator::SubtitleMarkSpacing.new(filename, @logger, @reporter, @options).run
        end

        # Validate that every paragraph in the content_at file begins with a subtitle_mark
        validate_files(:content_at_files) do |filename|
          Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
            filename, @logger, @reporter, @options.merge(:content_type => :content)
          ).run
        end

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
            @options.merge(:subtitle_import_consistency_compare_mode => 'roundtrip')
          ).run
        end

        # Validate content_at files
        validate_files(:content_at_files) do |filename|
          Validator::Utf8Encoding.new(filename, @logger, @reporter, @options).run
          Validator::KramdownSyntaxAt.new(filename, @logger, @reporter, @options).run
        end
      end

    end
  end
end
