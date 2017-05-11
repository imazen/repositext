class Repositext
  class Process
    class Compute
      class SubtitleContentChangesForFile
        # Uses stid to compute the score.
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
              return default_gap_penalty * 2
            end

            # We compute score based on stid only
            left_el.persistent_id == right_el.persistent_id ? 10 : 0
          end

          def default_gap_penalty
            -10
          end

          def gap_indicator
            nil
          end

        end
      end
    end
  end
end
