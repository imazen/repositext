class Repositext
  class Validation
    class Validator
      # This validator makes sure that validated text files have correct line
      # endings:
      # We want \n (Line feed) only, no \r (Carriage return).
      class CorrectLineEndings < Validator

        def run
          document_to_validate = @file_to_validate.read
          outcome = correct_line_endings?(document_to_validate)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        def correct_line_endings?(a_string)
          if a_string.index("\r")
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate.path],
                  ['Invalid line endings', "Repositext requires \\n (line feed) only, no \\r (carriage return)."]
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
