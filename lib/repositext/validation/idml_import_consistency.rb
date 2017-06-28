class Repositext
  class Validation
    # Validation to make sure no content was changed during IDML import.
    class IdmlImportConsistency < Validation

      # Specifies validations to run related to Idml import consistency.
      # Run this migration after IDML has been imported and record_ids have
      # been merged.
      # This validation makes sure that no text was changed inadvertently.
      def run_list
        # File pairs

        # Validate that plain text between idml_import_at and resulting content_at
        # are consistent.
        content_at_file_name_proc = lambda { |input_filename, file_specs|
          input_filename.gsub('/idml_import/', '/content/') \
                        .gsub('.idml.at', '.at')
        }
        # Run pairwise validation
        validate_file_pairs(:idml_import_at_files, content_at_file_name_proc) do |iia, ca|
          # skip if corresponding primary file doesn't exist
          next  if !File.exist?(ca)
          Validator::IdmlImportConsistency.new(
            [File.open(iia), File.open(ca)], @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
