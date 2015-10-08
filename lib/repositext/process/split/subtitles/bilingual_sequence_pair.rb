class Repositext
  class Process
    class Split
      class Subtitles

        # Represents a pair of corresponding sequences in primary and foreign language.
        class BilingualSequencePair

          # Creates an instance of self from two aligned sequences with unaligned
          # paragraphs.
          # @param primary_sequence [Sequence] primary plain text
          # @param foreign_sequence [Sequence] foreign plain text
          # @return [BilingualSequencePair] with aligned plain text paragraphs
          def initialize(primary_sequence, foreign_sequence)
            raise ArgumentError.new("Invalid primary_sequence: #{ primary_sequence.inspect }")  unless primary_sequence.is_a?(Sequence)
            raise ArgumentError.new("Invalid foreign_sequence: #{ foreign_sequence.inspect }")  unless foreign_sequence.is_a?(Sequence)
            @primary_sequence = primary_sequence
            @foreign_sequence = foreign_sequence
          end

          # Returns aligned paragraph pairs
          # @return [Array<BilingualParagraphPair>]
          def aligned_paragraph_pairs
            @aligned_paragraph_pairs ||= compute_aligned_paragraph_pairs(
              @primary_sequence, @foreign_sequence
            )
          end

          # Returns paragraphs' aggregated confidence stats.
          # @return [Hash]
          def confidence_stats
            max = nil
            min = nil
            means = []
            medians = []
            aligned_paragraph_pairs.each { |e|
              max = max.nil? ? e.confidence_stats[:max] : [max, e.confidence_stats[:max]].max
              min = min.nil? ? e.confidence_stats[:min] : [min, e.confidence_stats[:min]].min
              means << e.confidence_stats[:mean]
              medians << e.confidence_stats[:median]
            }
            {
              max: max,
              min: min,
              mean: means.mean,
              median: medians.median,
              count: aligned_paragraph_pairs.length,
            }
          end

        private

          # Aligns paragraphs of primary_sequence and foreign_sequence.
          # @param primary_sequence [Sequence] primary plain text
          # @param foreign_sequence [Sequence] foreign plain text
          # @return [Array<BilingualParagraphPair>] Array of aligned paragraph pairs.
          def compute_aligned_paragraph_pairs(primary_sequence, foreign_sequence)
            ParagraphsAligner.new(
              primary_sequence,
              foreign_sequence
            ).align.result
          end

        end

      end
    end
  end
end
