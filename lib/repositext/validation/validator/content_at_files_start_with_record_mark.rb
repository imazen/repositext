class Repositext
  class Validation
    class Validator
      # This validator makes sure that content AT files start with a record mark.
      class ContentAtFilesStartWithRecordMark < Validator

        def run
          document_to_validate = @file_to_validate.read
          outcome = correct_line_endings?(document_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        def correct_line_endings?(a_string)
          if a_string !~ /\A\^/
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate.path],
                  ["Content AT file doesn't start with record_mark", "Starts with #{ a_string.codepoints.first.inspect } instead."]
                )
              ]
            )
          else
            Outcome.new(true, nil)
          end
        end

      end
    end
  end
end
