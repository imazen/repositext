class Repositext
  class Validation
    class Validator
      # Validates that a content AT file in /content contains the same
      # number of subtitle_marks as the corresponding subtitle_marker csv file.
      class SubtitleMarkCountsMatch < Validator

        # Runs all validations for self
        def run
          content_at_filename, subtitle_marker_csv_filename = @file_to_validate
          errors, warnings = [], []

          catch(:abandon) do
            outcome = subtitle_mark_counts_match?(
              content_at_filename.read,
              subtitle_marker_csv_filename.read
            )
            if outcome.fail?
              errors += outcome.errors
              warnings += outcome.warnings
              #throw :abandon
            end
          end

          log_and_report_validation_step(errors, warnings)
        end

      private

        # Checks if content_at and subtitle_marker_csv contain the same number of
        # subtitle_marks.
        # @param[String] content_at
        # @param[CSV] subtitle_marker_csv
        # @return[Outcome]
        def subtitle_mark_counts_match?(content_at, subtitle_marker_csv)
          content_at_count = content_at.count('@')
          subtitle_marker_csv_count = subtitle_marker_csv.strip.count("\n")

          # compare the two counts
          if 0 == content_at_count || content_at_count == subtitle_marker_csv_count
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  [@file_to_validate.last.path],
                  [
                    'Subtitle_mark count mismatch',
                    "content_at contains #{ content_at_count }, but subtitle_marker_csv contains #{ subtitle_marker_csv_count } subtitle_marks."
                  ]
                )
              ]
            )
          end
        end

      end
    end
  end
end
