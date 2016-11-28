class Repositext
  class Process
    class Report
      class QuoteOfTheDayDiscrepancies
        # Aligns QOTD and content AT
        class QotdToContentAtAligner < NeedlemanWunschAligner

          # Get score for alignment pair of lines.
          #
          # @param qotd [String] qotd line
          # @param content_at [String] content AT line
          # @return [Float] between 0.0 and 1.0
          def compute_score(qotd, content_at, _, _)
            return 0  if qotd.nil?

            qotd_length = qotd.length
            content_at_length = content_at.length

            ca_segments = if content_at_length > qotd_length
              # qotd line is not a complete line (it is shorter than content AT).
              # We compare it to start and end of content AT line and use the
              # greater similarity.
              [
                [0, qotd_length],
                [-qotd_length, qotd_length]
              ].map { |start, length| content_at[start, length] }
            else
              [content_at]
            end

            similarity = ca_segments.map { |e|
              qotd.longest_subsequence_similar(e)
            }.max
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
