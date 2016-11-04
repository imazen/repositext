class Repositext
  class Process
    class Report
      class QuoteOfTheDayDiscrepancies
        # Aligns QOTD and content AT
        class QotdToContentAtAligner < NeedlemanWunschAligner

          # Get score for alignment pair of lines.
          #
          # @param left_el [SubtitleAttrs] content AT line
          # @param right_el [SubtitleAttrs] qotd line
          # @return [Float] between 0.0 and 1.0
          def compute_score(left_el, right_el, _, _)
            similarity = left_el.longest_subsequence_similar(right_el)
          end

          def default_gap_penalty
            -1
          end

          def gap_indicator
            nil
          end

        end
      end
    end
  end
end
