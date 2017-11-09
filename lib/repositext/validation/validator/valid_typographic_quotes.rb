class Repositext
  class Validation
    class Validator
      # Finds any invalid typographic quotes (unmatched opening and closing quotes)
      class ValidTypographicQuotes < Validator

        # Runs all validations for self
        def run
          content_at_file = @file_to_validate
          outcome = typographic_quotes_are_valid?(content_at_file)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # @param content_at_file [RFile::ContentAt]
        # @return [Outcome]
        def typographic_quotes_are_valid?(content_at_file)
          report = Repositext::Process::Report::InvalidTypographicQuotes.new(
            5,
            content_at_file.language
          )
          report.process(
            content_at_file.contents,
            content_at_file.filename
          )
          errors = []
          warnings = []
          report.results.each { |(filename, instances)|
            instances.each { |instance|
              errors << Reportable.error(
                {
                  filename: filename,
                  line: instance[:line],
                  context: instance[:excerpt],
                },
                ['Invalid typographic quote']
              )
            }
          }

          Outcome.new(
            errors.empty?,
            nil,
            [],
            errors,
            warnings
          )
        end

      end
    end
  end
end
