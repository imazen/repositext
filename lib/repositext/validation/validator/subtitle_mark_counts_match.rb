class Repositext
  class Validation
    class Validator
      # Validates that a content AT file in /content contains the same
      # number of subtitle_marks as the corresponding subtitle_marker csv file.
      class SubtitleMarkCountsMatch < Validator

        # Runs all validations for self
        def run
          content_at_file, subtitle_marker_csv_file = @file_to_validate
          outcome = subtitle_mark_counts_match?(
            content_at_file,
            subtitle_marker_csv_file
          )
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if content_at and subtitle_marker_csv contain the same number of
        # subtitle_marks.
        # @param content_at_file [RFile::ContentAt]
        # @param stm_csv_file [RFile::SubtitleMarkerCsv]
        # @return [Outcome]
        def subtitle_mark_counts_match?(content_at_file, stm_csv_file)
          content_at_count = Services::ExtractSubtitleMarkCountContentAt.call(content_at_file.contents)
          stm_csv_count = Services::ExtractSubtitleMarkCountStmCsv.call(stm_csv_file.contents)

          # compare the two counts
          if 0 == content_at_count || content_at_count == stm_csv_count
            Outcome.new(true, nil)
          else
            Outcome.new(
              false, nil, [],
              [
                Reportable.error(
                  {
                    filename: content_at_file.filename,
                    corr_filename: stm_csv_file.filename,
                  },
                  [
                    'Subtitle_mark count mismatch',
                    "content_at contains #{ content_at_count }, but subtitle_marker_csv contains #{ stm_csv_count } subtitle_marks."
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
