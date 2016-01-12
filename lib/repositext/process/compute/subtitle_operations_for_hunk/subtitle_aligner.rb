class Repositext
  class Process
    class Compute
      class SubtitleOperationsForHunk

        # Uses the Jaccard similarity to compute the score.
        class SubtitleAligner < NeedlemanWunschAligner

          # Get score for alignment pair of subtitle grains.
          # Each grain looks like this:
          #
          # {
          #   content: "the full content",
          #   length: 7,
          #   stid: 'todo',
          # }
          #
          # param left_el [Hash]
          # param right_el [Hash]
          # return [Integer]
          def compute_score(left_el, right_el)
            100 * JaccardSimilarityComputer.compute(
              left_el[:content],
              right_el[:content]
            )
          end

          def default_gap_penalty
            -10
          end

          def gap_indicator
            { type: :gap }
          end

        end

      end
    end
  end
end
