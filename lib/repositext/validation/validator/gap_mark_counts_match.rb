class Repositext
  class Validation
    class Validator
      # Validates that two files contain the same number of gap_marks.
      class GapMarkCountsMatch < Validator

        class GapMarkCountMismatchError < ::StandardError; end

        # Runs all validations for self
        def run
          file_1, file_2 = @file_to_validate
          outcome = gap_mark_counts_match?(file_1, file_2)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if doc_1 and doc_2 contain the same number of gap_marks in each
        # line.
        # @param r_file_1 [RFile]
        # @param r_file_2 [RFile]
        # @return [Outcome]
        def gap_mark_counts_match?(r_file_1, r_file_2)
          doc_1_lines = r_file_1.split("\n")
          doc_2_lines = r_file_2.split("\n")

          mismatching_lines = []
          doc_1_lines.each_with_index do |l1, idx|
            l2 = doc_2_lines[idx]
            next  if l1.count('%') == l2.count('%')
            # counts mismatch
            mismatching_lines << {
              line: idx + 1,
              txt1: l1,
              txt2: l2
            }
          end
          if mismatching_lines.any?
            # We want to terminate if the gap_mark count is inconsistent.
            # Normally we'd return a negative outcome (see below), but in this
            # case we raise an exception.
            # Outcome.new(
            #   false, nil, [],
            #   [
            #     Reportable.error(
            #       [@file_to_validate.last.filename],
            #       [
            #         'Gap_mark count mismatch',
            #         "file 1 contains #{ doc_1_count }, but file 2 contains #{ doc_2_count } gap_marks."
            #       ]
            #     )
            #   ]
            # )
            raise GapMarkCountMismatchError.new(
              [
                "The two files have different numbers of gap marks",
                "Cannot proceed. Please resolve gap_mark differences first:",
                mismatching_lines.inspect
              ].join("\n")
            )
          end
        end

      end
    end
  end
end
