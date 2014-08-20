class Repositext
  class Validation
    class SubtitlePreImport < Validation

      # Specifies validations to run before subtitle/subtitle_tagging import.
      def run_list
        # Validate that the subtitle/subtitle_tagging import still matches content_at
        # Define proc that computes subtitle/subtitle_tagging import filename from content_at filename
        si_file_name_proc = lambda { |input_filename, file_specs|
          ca_base_dir, ca_file_pattern = file_specs[:content_at_files]
          si_base_dir, si_file_pattern = file_specs[:subtitle_import_files]
          Repositext::Utils::SubtitleFilenameConverter.convert_from_repositext_to_subtitle_import(
            input_filename.gsub(ca_base_dir, si_base_dir)
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, si_file_name_proc) do |ca_filename, si_filename|
          Validator::SubtitleImportConsistency.new(
            [ca_filename, si_filename],
            @logger,
            @reporter,
            @options.merge(:subtitle_import_consistency_compare_mode => 'pre_import')
          ).run
        end

        # Validate that every paragraph in the import file begins with a subtitle_mark
        validate_files(:subtitle_import_files) do |file_name|
          next  if file_name.index('markers.') # skip markers files
          Validator::SubtitleMarkAtBeginningOfEveryParagraph.new(
            file_name, @logger, @reporter, @options.merge(:content_type => :import)
          ).run
        end
      end

    end
  end
end
