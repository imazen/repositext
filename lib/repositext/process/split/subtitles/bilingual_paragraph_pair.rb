class Repositext
  class Process
    class Split
      class Subtitles

        # Represents a pair of corresponding paragraphs in primary and foreign language.
        class BilingualParagraphPair

          attr_reader :bilingual_text_pairs

          # @param bilingual_text_pairs [Array<BilingualTextPair>]
          def initialize(bilingual_text_pairs)
            raise ArgumentError.new("Invalid bilingual_text_pairs: #{ bilingual_text_pairs.inspect }")  unless bilingual_text_pairs.is_a?(Array)
            @bilingual_text_pairs = bilingual_text_pairs
          end

        end

      end
    end
  end
end
