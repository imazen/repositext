class Repositext
  class Process
    class Compute
      class SubtitleOperationsForHunk

        # Computes Jaccard similarity of two strings
        class JaccardSimilarityComputer

          # Computes JaccardSimilarity of strings a and b plus a confidence indicator.
          #
          # @param a [String]
          # @param b [String]
          # @param truncate_to_shortes [Boolean, optional]
          # @param alignment [Symbol, optional] :left or :right
          # @return [Array<Float>] Array with two elements:
          #   First for similarity: 1.0 for identical, 0.0 for entirely dissimilar
          #   Second for confidence: 1.0 is highest confidence, 0.0 is lowest confidence
          def self.compute(a, b, truncate_to_shortest = true, alignment = :left)
            # Prepare strings
            if truncate_to_shortest
              max_len = [a.length, b.length].min
              case alignment
              when :left
                string_a = a[0, max_len]
                string_b = b[0, max_len]
              when :right
                string_a = a[-max_len..-1]
                string_b = b[-max_len..-1]
              else
                raise "Handle this: #{ alignment.inspect }"
              end
            else
              string_a = a
              string_b = b
            end

            # Return max similarity and confidence if strings are identical
            return [1.0, 1.0]  if string_a == string_b && '' != string_a

            # Compute sets
            set_a = tokenize_string(string_a)
            set_b = tokenize_string(string_b)
            intersection = set_a & set_b
            union        = set_a + set_b
            return [0.0, 0.0]  if 0 == union.length

            # Compute similarity
            similarity = intersection.length / union.length.to_f

            # Compute confidence
            min_set_length = [set_a.length, set_b.length].min
            # Reach max confidence at 10 tokens
            confidence = [(min_set_length / 10.0), 1.0].min

            [similarity, confidence]
          end

          # @param s [String]
          # @return [Array<String>]
          def self.tokenize_string(s)
            Set.new(s.split(/\s+/))
          end

        end

      end
    end
  end
end
