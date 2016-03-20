class Repositext
  class Validation
    class PdfExport < Validation

      # Specifies validations to run related to PDF export.
      def run_list
        validate_files(:exported_pdfs) do |path|
          Validator::PdfExportConsistency.new(
            path, @logger, @reporter, @options
          ).run
        end
      end

    end
  end
end
