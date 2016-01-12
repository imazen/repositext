class Repositext
  class Process
    class Compute
      class SubtitleOperationsForHunk

        # Computes Jaccard similarity of two strings
        class JaccardSimilarityComputer

          # @param a [String]
          # @param b [String]
          # @param truncate_to_shortes [Boolean, optional]
          # @param alignment [Symbol, optional] :left or :right
          # @return [Float] 1.0 for identical, 0.0 for entirely dissimilar
          def self.compute(a, b, truncate_to_shortest = true, alignment = :left)
            # Prepare strings
            if truncate_to_shortest
              max_len = [a.length, b.length].min
              case alignment
              when :left
                set_a = tokenize_string(a[0, max_len])
                set_b = tokenize_string(b[0, max_len])
              when :right
                set_a = tokenize_string(a[-max_len..-1])
                set_b = tokenize_string(b[-max_len..-1])
              else
                raise "Handle this: #{ alignment.inspect }"
              end
            else
              set_a = tokenize_string(a)
              set_b = tokenize_string(b)
            end

            intersection = set_a & set_b
            union        = set_a + set_b
            return 0.0  if 0 == union.length
            intersection.length / union.length.to_f
          end

          # @param s [String]
          # @return [Array<String>]
          def self.tokenize_string(s)
            Set.new(s.split)
          end

        end

      end
    end
  end
end
