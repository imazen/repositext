class Repositext
  class Validation
    class DocxPreImport < Validation

      # Specifies validations to run related to Docx import.
      def run_list
        validate_files(:docx_sources) do |path|
          # Validator::DocxImportSyntax.new(
          #   File.open(path), @logger, @reporter, @options
          # ).run
          # Validator::IdmlImportRoundTrip.new(
          #   File.open(path), @logger, @reporter, @options
          # ).run
        end
      end

    end
  end
end
