class Repositext
  class Validation
    class Validator
      # This validator makes sure that validated text files have correct line
      # endings:
      # We want \n (Line feed) only, no \r (Carriage return).
      class CorrectLineEndings < Validator

        def run
          content_at_file = @file_to_validate
          outcome = correct_line_endings?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        def correct_line_endings?(content_at_file)
          if content_at_file.contents.index("\r")
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  { filename: content_at_file.filename },
                  [
                    'Invalid line endings',
                    "Repositext requires \\n (line feed) only, no \\r (carriage return)."
                  ]
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
