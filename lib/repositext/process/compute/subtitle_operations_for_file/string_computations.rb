class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile

        # Computes Longest Common Subsequence similarity of two strings.
        class StringComputations

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
          def self.similarity(a, b, truncate_to_shortest = 100_000, alignment = :left)
            min_string_length, max_string_length = [a.length, b.length].minmax
            return [0.0, 0.0]  if 0 == min_string_length

            # Number of characters compared to reach max confidence.
            max_conf_at_char_length = 15

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

              confidence = [(max_string_length / max_conf_at_char_length.to_f), 1.0].min
            end

            # Return max similarity and confidence if strings are identical
            return [1.0, 1.0]  if string_a == string_b && '' != string_a

            similarity = string_a.longest_subsequence_similar(string_b)

            [similarity, confidence]
          end

          # Detects if a_string contains any repeated sequences with minimum
          # length of ngram_length.
          # Example:
          #     "here we go repetition number one, repetition number two, repetition number three. And then some more"
          # will return this:
          #     { " repetition number " => [10, 33, 56] }
          # @param a_string [String]
          # @return [Hash] with repeated strings as keys and start positions as vals.
          def self.repetitions(a_string)
            ngram_length = 12 # based on min length of offensive repeat phrases in production content
            string_length = a_string.length
            return {}  if string_length <= ngram_length

            start_pos = 0
            ngrams = {}
            while(start_pos + ngram_length) <= string_length do
              test_string = a_string[start_pos, ngram_length]
              ngrams[test_string]  ||= []
              ngrams[test_string] << start_pos
              start_pos += 1
            end

            max_rep_count = ngrams.inject(0) { |m,(k,v)| [m, v.length].max }
            return {}  if max_rep_count <= 1

            reps = ngrams.inject({}) { |m,(k,v)|
              m[k] = v  if v.length == max_rep_count
              m
            }

            # reps looks like this:
            # {
            #   " repetitio"=>[10, 33, 56],
            #   "repetition"=>[11, 34, 57],
            #   "epetition "=>[12, 35, 58],
            #   "petition n"=>[13, 36, 59],
            #   "etition nu"=>[14, 37, 60],
            #   "tition num"=>[15, 38, 61],
            #   "ition numb"=>[16, 39, 62],
            #   "tion numbe"=>[17, 40, 63],
            #   "ion number"=>[18, 41, 64],
            #   "on number "=>[19, 42, 65]
            # }

            current_start_pos = -2
            prev_key = nil
            expanded_reps = reps.inject({}) { |m,(k,v)|
              if current_start_pos.succ == v.first
                # is connected, combine the two
                new_key = prev_key + k.last
                m[new_key] = m.delete(prev_key) || v
                prev_key = new_key
              else
                # Not connected, start new capture group
                m[k] = v
                prev_key = k
              end
              current_start_pos = v.first
              m
            }

            expanded_reps
          end

          # This method measures by how many characters the end of string_a
          # overlaps with the beginning of string_b.
          # It determines the overlap in characters at which the similarity
          # surpasses a similarity threshold.
          #
          # It starts with a minimal overlap and keeps increasing overlap until
          # it reaches the length of the shorter of string_a or string_b. For
          # each overlap it computes the similarity, and when it has reached
          # sufficiently high similarity it returns the numbers of characters that
          # overlap. Otherwise it returns zero.\
          #
          # NOTE: This method assumes that string_a and string_b are not very
          # similar. This method should only get called for dissimilar strings.
          # If we find we call this for similar strings, then we could further
          # optimize it, e.g., by computing the overall string similarity and
          # returning that if it is high enough.
          # @param string_a [String]
          # @param string_b [String]
          # @param threshold [Float, optional]
          # @param debug [Boolean, optional]
          # @return [Integer] Number of overlapping characters
          def self.overlap(string_a, string_b, threshold=nil, debug=false)
            threshold ||= 0.67 # so that we can pass nil as argument and still get default
            min_string_length = [string_a, string_b].map(&:length).min
            return 0  if min_string_length < min_overlap

            max_sim = 0
            prev_sim = 0
            overlap = min_overlap
            keep_going = true
            reached_sufficient_similarity = false

            while keep_going do

              string_a_end = string_a[-overlap..-1]
              string_b_start = string_b[0..(overlap-1)]
              sim = string_a_end.longest_subsequence_similar(string_b_start)

              if debug
                puts ''
                puts [
                  ('█' * (sim * 10).round).rjust(10),
                  ' ',
                  string_a_end.inspect
                ].join
                puts [
                  sim.round(3).to_s.rjust(10).color(prev_sim <= sim ? :green : :red),
                  ' ',
                  string_b_start.inspect
                ].join
              end

              if sim > max_sim
                optimal_overlap = overlap
              end
              max_sim = [max_sim, sim].max
              reached_sufficient_similarity = sufficient_overlap_similarity?(
                max_sim,
                overlap,
                threshold
              )
              keep_going = !reached_sufficient_similarity && overlap < min_string_length
              prev_sim = sim
              overlap += 1
            end
            r = if reached_sufficient_similarity
              optimal_overlap
            else
              0
            end
            puts "Returned overlap chars: #{ r }"  if debug
            r
          end

          # Returns true if sim is sufficient for the given overlap.
          # @param sim [Float]
          # @param overlap [Integer]
          # @param sim_threshold [Float]
          # @return [Boolean]
          def self.sufficient_overlap_similarity?(sim, overlap, sim_threshold)
            case overlap
            when 0..(min_overlap - 1)
              # Insufficient overlap
              false
            when min_overlap..5
              # Perfect match required for small overlap
              1.0 == sim
            else
              # Min of sim_threshold
              sim >= sim_threshold
            end
          end

          # Returns minimum number of characters to be considered an overlap
          def self.min_overlap
            3
          end

        end
      end
    end
  end
end
