class Repositext
  class Validation
    # Validation to run after a DOCX import.
    class DocxPostImport < Validation

      # Specifies validations to run related to Docx import.
      def run_list

        # Single files
        validate_files(:imported_repositext_files) do |repositext_file|
          Validator::Utf8Encoding.new(
            File.open(repositext_file.filename), @logger, @reporter, @options
          ).run
        end
        validate_files(:imported_at_files) do |f_content_at_file|
          @options['run_options'] << 'kramdown_syntax_at-no_underscore_or_caret'
          Validator::KramdownSyntaxAt.new(
            File.open(f_content_at_file.filename), @logger, @reporter, @options
          ).run
          if @options['content_type'].is_primary_repo
            Validator::ParagraphNumberSequencing.new(
              File.open(f_content_at_file.filename), @logger, @reporter, @options
            ).run
          else
            # Check pn alignment with primary, which also implies correct sequencing.
            Validator::DocxImportForeignConsistency.new(
              f_content_at_file, @logger, @reporter, @options
            ).run
            Validator::ParagraphStyleConsistency.new(
              [f_content_at_file, f_content_at_file.corresponding_primary_file],
              @logger,
              @reporter,
              @options
            ).run
          end
        end

      end

    end
  end
end
