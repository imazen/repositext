class Repositext
  class Validation
    class Validator
      # This validator makes sure that content AT files start with a record mark.
      class ContentAtFilesStartWithRecordMark < Validator

        def run
          content_at_file = @file_to_validate
          outcome = starts_with_record_mark?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

        def starts_with_record_mark?(content_at_file)
          if content_at_file.contents !~ /\A\^/
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  {
                    filename: content_at_file.filename,
                    line: 1,
                    context: content_at_file.contents[0,20].inspect
                  },
                  [
                    "Content AT file doesn't start with record_mark",
                    "Starts with #{ content_at_file.contents.codepoints.first.inspect } instead."
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
