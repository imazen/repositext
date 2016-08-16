class Repositext
  class Validation
    class DocxPreImport < Validation

      # Specifies validations to run related to Docx import.
      def run_list
        validate_files(:docx_files) do |docx_file|
          Validator::DocxImportWorkflow.new(
            docx_file, @logger, @reporter, @options
          ).run
          Validator::DocxImportSyntax.new(
            docx_file, @logger, @reporter, @options
          ).run
          # TODO: Decide if we want to run this validation:
          # Validator::DocxImportRoundTrip.new(
          #   docx_file, @logger, @reporter, @options
          # ).run
        end
      end

    end
  end
end
