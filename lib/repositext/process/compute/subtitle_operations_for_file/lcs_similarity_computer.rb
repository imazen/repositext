class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile

        # Computes Longest Common Subsequence similarity of two strings.
        class LcsSimilarityComputer

          # Computes Longest Common Subsequence similarity of strings a and b
          # plus a confidence indicator.
          #
          # @param a [String]
          # @param b [String]
          # @param truncate_to_shortest [Integer, optional] if given, will truncate to num chars
          # @param alignment [Symbol, optional] :left or :right
          # @return [Array<Float>] Array with two elements:
          #   First for similarity: 1.0 for identical, 0.0 for entirely dissimilar
          #   Second for confidence: 1.0 is highest confidence, 0.0 is lowest confidence
          def self.compute(a, b, truncate_to_shortest = 100_000, alignment = :left)
            min_string_length, max_string_length = [a.length, b.length].minmax
            return [0.0, 0.0]  if 0 == min_string_length

            # Number of characters compared to reach max confidence.
            max_conf_at_char_length = 30

            if truncate_to_shortest
              truncate_len = [min_string_length, truncate_to_shortest].min

              case alignment
              when :left
                string_a = a[0, truncate_len]
                string_b = b[0, truncate_len]
              when :right
                string_a = a[-truncate_len..-1]
                string_b = b[-truncate_len..-1]
              else
                raise "Handle this: #{ alignment.inspect }"
              end

              confidence = if truncate_len > max_conf_at_char_length
                # Max confidence if we compare at least max_conf_at_char_length chars
                1.0
              else
                # For situations where at least one string is shorter than
                # max_conf_at_char_length chars, confidence is determined by the
                # length difference between shortest string and max_conf_at_char_length.
                truncate_len / max_conf_at_char_length.to_f
              end
            else
              string_a = a
              string_b = b

              # Reach max confidence at 50 chars
              confidence = [(max_string_length / max_conf_at_char_length.to_f), 1.0].min
            end

            # Return max similarity and confidence if strings are identical
            return [1.0, 1.0]  if string_a == string_b && '' != string_a

            similarity = string_a.longest_subsequence_similar(string_b)

            [similarity, confidence]
          end
        end
      end
    end
  end
end
