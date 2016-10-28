class Repositext
  class Process
    class Split
      class Subtitles
        class BilingualSequencePair

          # Aligns foreign_sequence with primary_sequence.
          # Estimates positions based on paragraph numbers (no review required) and
          # counts (review required) or based on subtitle mark indexes (no review required).
          class ParagraphsAligner

            attr_reader :foreign_sequence, :primary_sequence

            # @param primary_sequence [Sequence] primary plain text
            # @param foreign_sequence [Sequence] foreign plain text
            # @param options [Hash, optional]
            #     structural_similarity_override
            def initialize(primary_sequence, foreign_sequence, options={})
              @primary_sequence = primary_sequence
              @foreign_sequence = foreign_sequence
              @options = options
            end

            # Returns outcome with aligned primary and foreign sequences.
            # @return [Outcome] with Array of BilingualParagraphPairs as result.
            def align
              # Determine synchronization strategy
              aligner_klass = pick_alignment_strategy(structural_similarity)
              aligner_klass.new(
                structural_similarity,
                primary_sequence,
                foreign_sequence
              ).align
            end

            def foreign_kramdown_doc
              @foreign_kramdown_doc ||= foreign_sequence.as_kramdown_doc(is_primary_repositext_file: false)
            end

            def primary_kramdown_doc
              @primary_kramdown_doc ||= primary_sequence.as_kramdown_doc(is_primary_repositext_file: true)
            end

            def structural_similarity
              @structural_similarity ||= (
                @options[:structural_similarity_override] ||
                compute_structural_similarity(
                  primary_kramdown_doc,
                  foreign_kramdown_doc
                )
              )
            end

          protected

            # @param primary_kd [Kramdown::Document]
            # @param foreign_kd [Kramdown::Document]
            def compute_structural_similarity(primary_kd, foreign_kd)
              Kramdown::TreeStructuralSimilarity.new(
                primary_kd,
                foreign_kd
              ).compute
            end

            # @param structural_similarity [Hash]
            #    * paragraph_count_similarity
            #    * paragraph_numbers_similarity
            #    * subtitle_count_similarity
            def pick_alignment_strategy(structural_similarity)
              if 1.0 == structural_similarity[:paragraph_numbers_similarity]
                WithIdenticalParagraphCounts
              else
                WithDifferentParagraphCounts
              end
            end

          end
        end
      end
    end
  end
end
