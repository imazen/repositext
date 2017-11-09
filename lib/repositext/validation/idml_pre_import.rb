class Repositext
  class Validation
    # Validation to run before an IDML import.
    class IdmlPreImport < Validation

      # Specifies validations to run related to Idml import.
      def run_list
        validate_files(:idml_sources) do |idml_file|
          Validator::IdmlImportSyntax.new(
            idml_file, @logger, @reporter, @options
          ).run
          Validator::IdmlImportRoundTrip.new(
            idml_file, @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
