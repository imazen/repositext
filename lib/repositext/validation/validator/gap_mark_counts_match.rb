class Repositext
  class Validation
    class Validator
      # Validates that two files contain the same number of gap_marks.
      class GapMarkCountsMatch < Validator

        class GapMarkCountMismatchError < ::StandardError; end

        # Runs all validations for self
        def run
          filename_1, filename_2 = @file_to_validate
          outcome = gap_mark_counts_match?(filename_1.read, filename_2.read)
          log_and_report_validation_step(outcome.errors, outcome.warnings)
        end

      private

        # Checks if doc_1 and doc_2 contain the same number of gap_marks in each
        # line.
        # @param [String] doc_1
        # @param [String] doc_2
        # @return [Outcome]
        def gap_mark_counts_match?(doc_1, doc_2)
          doc_1_lines = doc_1.split("\n")
          doc_2_lines = doc_2.split("\n")

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
            #       [@file_to_validate.last.path],
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
