class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair
          class ParagraphsAligner

            # This aligner uses the Needleman-Wunsch sequence alignment algorithm.
            class WithIdenticalParagraphCounts

              def initialize(structural_similarity, primary_sequence, foreign_sequence)
                # we don't need structural similarity
                @primary_sequence = primary_sequence
                @foreign_sequence = foreign_sequence
              end

              # Returns outcome with aligned primary and foreign paragraphs.
              # @return [Outcome] with Array of aligned BilingualParagraphPairs as result.
              def align
                Outcome.new(
                  true,
                  @primary_sequence.paragraphs.each_with_index.map { |primary_paragraph, idx|
                    foreign_paragraph = @foreign_sequence.paragraphs[idx]
                    BilingualParagraphPair.new(primary_paragraph, foreign_paragraph)
                  }
                )
              end

            end

          end
        end
      end
    end
  end
end
