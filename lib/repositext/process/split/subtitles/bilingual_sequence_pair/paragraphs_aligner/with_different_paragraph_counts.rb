class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair
          class ParagraphsAligner

            # This aligner uses the Needleman-Wunsch sequence alignment algorithm.
            class WithDifferentParagraphCounts

              # @param structural_similarity [Hash]
              # @param primary_sequence [Sequence]
              # @param foreign_sequence [Sequence]
              def initialize(structural_similarity, primary_sequence, foreign_sequence)
                # we don't need structural similarity
                @primary_sequence = primary_sequence
                @foreign_sequence = foreign_sequence
              end

              # Returns outcome with aligned primary and foreign paragraphs.
              # @return [Outcome] with Array of aligned BilingualParagraphPairs as result.
              def align
                Outcome.new(true, align_with_nw_algorithm)
              end

            protected

              def align_with_nw_algorithm
                # convert to alignable block elements
                primary_block_elements = compute_primary_block_elements
                foreign_block_elements = compute_foreign_block_elements

                # align both sequences of block_elements
                aligned_primary_block_elements, aligned_foreign_block_elements = compute_aligned_block_elements(
                  primary_block_elements,
                  foreign_block_elements
                )

                aligned_primary_block_elements.each_with_index.map { |primary_block_element, idx|
                  foreign_block_element = aligned_foreign_block_elements[idx]
                  BilingualParagraphPair.new(
                    Paragraph.new(primary_block_element.to_kramdown, @primary_sequence.language),
                    Paragraph.new(foreign_block_element.to_kramdown, @foreign_sequence.language),
                    compute_block_element_pair_confidence(
                      primary_block_element, foreign_block_element
                    )
                  )
                }
              end

              def compute_block_element_pair_confidence(primary_el, foreign_el)
                current_primary_paragraph = nil
                current_foreign_paragraph = nil
                if primary_el.type == foreign_el.type
                  # same type
                  if primary_el.key == foreign_el.key
                    # key, full confidence
                    1.0
                  else
                    # same type, different key, limited confidence
                    0.5
                  end
                elsif [primary_el.type, foreign_el.type].include?(:gap)
                  # A gap, no confidence
                  0.0
                else
                  pp primary_el
                  pp foreign_el
                  raise
                end
              end

              def compute_primary_block_elements
                @primary_sequence.as_kramdown_doc.to_paragraph_alignment_objects
              end

              def compute_foreign_block_elements
                @foreign_sequence.as_kramdown_doc.to_paragraph_alignment_objects
              end

              def compute_aligned_block_elements(primary_block_elements, foreign_block_elements)
                WithDifferentParagraphCounts::NwAligner.new(
                  primary_block_elements,
                  foreign_block_elements
                ).get_optimal_alignment
              end

            end

          end
        end
      end
    end
  end
end
