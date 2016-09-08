class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile

        # Uses the Jaccard similarity to compute the score.
        class SubtitleAligner < NeedlemanWunschAligner

          # Get score for alignment pair of subtitle attrs.
          #
          # @param left_el [SubtitleAttrs]
          # @param right_el [SubtitleAttrs]
          # @param row_index [Integer] in score matrix
          # @param col_index [Integer] in score matrix
          # @return [Float]
          def compute_score(left_el, right_el, row_index, col_index)

            # To improve performance, we only look at cells adjacent to
            # the matrix' diagonal. We can do this because we know the maximum
            # misalignment of subtitles from @options[:diagonal_band_range].
            # For cells outside of this band we return a very small negative
            # number as score so they are not considered when finding optimal
            # alignment.
            if (row_index - col_index).abs > @options[:diagonal_band_range]
              return -1000
            end

            # Remove everything except chars, numbers, and whitespace
            left_txt = left_el[:content_sim]
            right_txt = right_el[:content_sim]

            # First we compute unaligned similarity
            abs_sim, abs_conf = LcsSimilarityComputer.compute(
              left_txt,
              right_txt,
              false
            )

            abs_sim = 100 * abs_sim * (abs_conf < 0.7 ? abs_conf : 1.0)
            return abs_sim  if 100 == abs_sim

            # If strings are not identical, then we compute left aligned
            # similarity so that gaps come after the shared content on splits.
            left_aligned_sim, la_conf = LcsSimilarityComputer.compute(
              left_txt,
              right_txt,
              100_000,
              :left
            )
            left_aligned_sim = 100 * left_aligned_sim * (la_conf < 0.7 ? la_conf : 1.0)

            # Return larger of the two similarities
            [abs_sim, left_aligned_sim].max
          end

          def default_gap_penalty
            -10
          end

          def gap_indicator
            { content: '', content_sim: '', subtitle_count: 0 }
          end
        end
      end
    end
  end
end
