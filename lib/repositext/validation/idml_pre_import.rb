class Repositext
  class Validation
    class IdmlPreImport < Validation

      # Specifies validations to run related to Idml import.
      def run_list
        validate_files(:idml_sources) do |path|
          Validator::IdmlImportSyntax.new(
            File.open(path), @logger, @reporter, @options
          ).run
          Validator::IdmlImportRoundTrip.new(
            File.open(path), @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
