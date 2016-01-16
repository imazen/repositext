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
            jaccard_sim, jaccard_conf = JaccardSimilarityComputer.compute(
              left_el[:content],
              right_el[:content],
              false
            )
            abs_sim = 100 * jaccard_sim * jaccard_conf
            return abs_sim  if 100 == abs_sim
            # We boost left aligned similarity as it indicates that subtitles are aligned
            jaccard_sim, jaccard_conf = JaccardSimilarityComputer.compute(
              left_el[:content],
              right_el[:content],
              true,
              :left
            )
            left_aligned_sim = 100 * jaccard_sim * jaccard_conf
            # Return larger of the two similarities
            [abs_sim, left_aligned_sim].max
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
