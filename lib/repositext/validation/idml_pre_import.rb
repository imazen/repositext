class Repositext
  class Validation
    class IdmlPreImport < Validation

      # Specifies validations to run related to Idml import.
      def run_list
        validate_files(:idml_sources) do |file_name|
          Validator::IdmlImportSyntax.new(
            file_name, @logger, @reporter, @options
          ).run
          Validator::IdmlImportRoundTrip.new(
            file_name, @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
