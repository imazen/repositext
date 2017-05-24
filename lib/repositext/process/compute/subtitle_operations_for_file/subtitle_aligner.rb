class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        # Uses custom similarity computations to compute the score.
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

            case @options[:alignment_strategy]
            when :use_contents
              compute_score_using_contents(left_el, right_el)
            when :use_stids
              compute_score_using_stids(left_el, right_el)
            else
              raise "Handle this: #{ @options[:alignment_strategy].inspect }"
            end
          end

          # @param left_el [SubtitleAttrs]
          # @param right_el [SubtitleAttrs]
          # @return [Float]
          def compute_score_using_contents(left_el, right_el)
            left_txt = left_el[:content_sim]
            right_txt = right_el[:content_sim]

            max_score = 100 # maximum possible score
            sim_weight = 80 # percentage of score that is determined by similarity
            conf_weight = 10 # percentage of score that is determined by confidence
            length_weight = 10 # percentage of score that is determined by string length
            right_score_penalty = 20

            # Beginning eagle gets special treatment
            if [left_txt, right_txt].all? { |e| '' == e[0] }
              # Both start with eagle, we want to lock them together by giving
              # a very high score.
              return max_score * 2
            end

            # We add a length based bonus to each score so that given same
            # similarity, the longer string will win.
            min_length = [[left_txt, right_txt].map(&:length).min, 1].max # guaranteed to be 1 or greater
            length_bonus = length_weight * min_length / 120.0 # linear relationship of length

            # Compute left_aligned, absolute, and right_aligned similarities,
            # return the highest. Exit early if any of them are >= max_score
            abs_sim, abs_conf = StringComputations.similarity(
              left_txt,
              right_txt,
              false
            )
            abs_score = (sim_weight * abs_sim) + (conf_weight * abs_conf) + length_bonus
            if abs_score >= max_score
              return abs_score
            end

            # If strings are not identical, then we compute left aligned
            # similarity so that gaps come after the shared content on splits.
            left_sim, left_conf = StringComputations.similarity(
              left_txt,
              right_txt,
              100_000,
              :left
            )
            left_score = (sim_weight * left_sim) + (conf_weight * left_conf) + length_bonus
            if left_score >= max_score
              return left_score
            end

            # Last try right aligned
            right_sim, right_conf = StringComputations.similarity(
              left_txt,
              right_txt,
              100_000,
              :right
            )
            right_score = (sim_weight * right_sim) + (conf_weight * right_conf) + length_bonus
            # We prefer left alignment over right alignment. So given the same
            # similarity, we always want to prefer the left, even if the right
            # has a slightly higher score. We subtract right_score_penalty to
            # express the preference.
            right_score -= right_score_penalty

            # Return highest score
            highest_score = [abs_score, left_score, right_score].max

            if highest_score < 64
              # Penalize very low similarity scores, make them slightly worse
              # than a gap. This will avoid aligning of subtitle pairs that
              # have nothing in common.
              default_gap_penalty * 1.1
            else
              highest_score
            end
          end

          # @param left_el [SubtitleAttrs]
          # @param right_el [SubtitleAttrs]
          # @return [Float]
          def compute_score_using_stids(left_el, right_el)
            # We compute score based on stid only. A mismatch of non-nil stids
            # scores worse than a gap!
            Repositext::Service::ScoreSubtitleAlignmentUsingStid.call(
              left_stid: left_el[:persistent_id],
              right_stid: right_el[:persistent_id],
              default_gap_penalty: default_gap_penalty,
            )[:result]
          end

          def default_gap_penalty
            -10
          end

          def gap_indicator
            { content: '', content_sim: '', subtitle_count: 0, repetitions: {} }
          end

          def element_for_inspection_display(element, col_width = nil)
            r = element[:content_sim]
            col_width ? r[0...col_width] : r
          end

          def elements_are_equal_for_inspection(top_el, left_el)
            top_el[:content_sim] == left_el[:content_sim]
          end

        end
      end
    end
  end
end
