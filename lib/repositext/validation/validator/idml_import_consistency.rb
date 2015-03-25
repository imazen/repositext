class Repositext
  class Validation
    class Validator
      # Validates that no text was changed between importing IDML and merging
      # record_ids from Folio
      class IdmlImportConsistency < Validator

        # Runs all validations for self
        def run
          idml_import_at_file, content_at_file = @file_to_validate
          outcome = idml_import_consistent?(idml_import_at_file.read, content_at_file.read)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        # Checks if all text from IDML import is consistent with text in content.
        # @param idml_import_at [String]
        # @param content_at [String]
        # @return[Outcome]
        def idml_import_consistent?(idml_import_at, content_at)
          idml_import_at_doc = Kramdown::Document.new(idml_import_at, :input => 'KramdownRepositext')
          content_at_doc = Kramdown::Document.new(content_at, :input => 'KramdownRepositext')

          idml_import_at_plain_text = idml_import_at_doc.to_plain_text
          content_at_plain_text = content_at_doc.to_plain_text

          # A.D., A.M., and B.C. are lower cased after record ids were merged
          # as part of the import command. We lower case them in both to
          # avoid getting validation errors from this.
          idml_import_at_plain_text.gsub!(/A\.D\./, 'a.d.')
          idml_import_at_plain_text.gsub!(/A\.M\./, 'a.m.')
          idml_import_at_plain_text.gsub!(/B\.C\./, 'b.c.')
          content_at_plain_text.gsub!(/A\.D\./, 'a.d.')
          content_at_plain_text.gsub!(/A\.M\./, 'a.m.')
          content_at_plain_text.gsub!(/B\.C\./, 'b.c.')

          diffs = Suspension::StringComparer.compare(idml_import_at_plain_text, content_at_plain_text)

          if diffs.empty?
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              diffs.map { |diff|
                Reportable.error(
                  [@file_to_validate.first.path],
                  ['Plain text diference between idml_import_at and content_at', diff]
                )
              }
            )
          end
        end

      end
    end
  end
end
