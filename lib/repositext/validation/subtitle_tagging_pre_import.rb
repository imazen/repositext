class Repositext
  class Validation
    class SubtitleTaggingPreImport < Validation

      # Specifies validations to run before subtitle_tagging import.
      def run_list
        # Validate that the subtitle_tagging_import still matches content_at
        # Define proc that computes subtitle_tagging_import filename from content_at filename
        sti_file_name_proc = lambda { |input_filename, file_specs|
          ca_base_dir, ca_file_pattern = file_specs[:content_at_files]
          sti_base_dir, sti_file_pattern = file_specs[:subtitle_tagging_import_files]
          Repositext::Utils::SubtitleTaggingFilenameConverter.convert_from_repositext_to_subtitle_tagging_import(
            input_filename.gsub(ca_base_dir, sti_base_dir)
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, sti_file_name_proc) do |ca_filename, sti_filename|
          Validator::SubtitleTaggingImportConsistency.new(
            [ca_filename, sti_filename], @logger, @reporter, @options
          ).run
        end

        # Validate that the subtitle_tagging_export still matches content_at
        # Define proc that computes subtitle_tagging_export filename from content_at filename
        ste_file_name_proc = lambda { |input_filename, file_specs|
          ca_base_dir, ca_file_pattern = file_specs[:content_at_files]
          ste_base_dir, ste_file_pattern = file_specs[:subtitle_tagging_export_files]
          Repositext::Utils::SubtitleTaggingFilenameConverter.convert_from_repositext_to_subtitle_tagging_export(
            input_filename.gsub(ca_base_dir, ste_base_dir),
            { :extension => 'rt.txt' }
          )
        }
        # Run pairwise validation
        validate_file_pairs(:content_at_files, ste_file_name_proc) do |ca_filename, ste_filename|
          Validator::SubtitleTaggingExportConsistency.new(
            [ca_filename, ste_filename], @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
