class Repositext
  class Validation
    # Validation to run after a DOCX export.
    class DocxPostExport < Validation

      # Specifies validations to run related to Docx export.
      def run_list

        # Single files
        validate_files(:exported_docx_files) do |docx_file|
          Validator::DocxExportConsistency.new(
            docx_file, @logger, @reporter, @options
          ).run
        end

      end

    end
  end
end
