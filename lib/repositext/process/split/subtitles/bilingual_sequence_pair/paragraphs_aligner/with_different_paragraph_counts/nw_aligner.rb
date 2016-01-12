class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair
          class ParagraphsAligner
            class WithDifferentParagraphCounts

              class NwAligner < ::NeedlemanWunschAligner

                # Get score for alignment pair of records and paragraphs.
                # param left_el [BlockElement]
                # param right_el [BlockElement]
                # return [Integer]
                def compute_score(left_el, right_el)
                  score = 0
                  if left_el.type == right_el.type && left_el.key == right_el.key
                    # Extra boost if two headers are aligned
                    score += :header == left_el.type ? 20 : 10
                  elsif [left_el, right_el].any? { |e| :p == e.type }
                    if left_el.type == right_el.type
                      # difference in keys
                      score -= 25
                    else
                      # difference in type
                      score -= 50
                    end
                  else
                    raise "Handle this: #{ [left_el, right_el].inspect }"
                  end
                  score
                end

                def default_gap_penalty
                  -10
                end

                def gap_indicator
                  Kramdown::Converter::ParagraphAlignmentObjects::BlockElement.new(type: :gap)
                end

              end
            end
          end
        end
      end
    end
  end
end
