class Repositext
  class Utils
    # Compares strings and returns diffs
    class StringComparer

      # Compares string_1 with string_2 using diff_match_patch.
      # @param[String] string_1
      # @param[String] string_2
      # @return[Array] An array of diffs like so:
      # [[1, 'added', 'line 42', 'text_before text_after'], [-1, 'removed ', 'line 43', 'text_before removed text_after']]
      # All information is relative to string_1. 1 means a string was added, -1 it was deleted.
      # All contextual information is based on string_1
      def self.compare(string_1, string_2)
        if string_1 == string_2
          return []
        else
          diffs = Suspension::DiffAlgorithm.new.call(string_1, string_2)
          deltas = []
          char_num = 0
          line_num = 0
          excerpt_window = 20
          # Add context information to diffs
          deltas = diffs.map { |diff|
            excerpt_start = [(char_num - excerpt_window), 0].max
            excerpt_end = [(char_num + diff.last.length + excerpt_window), string_1.length].min
            excerpt = case diff.first
            when -1, 1
              string_1[excerpt_start..excerpt_end]
            when 0
              nil
            else
              raise "Handle this: #{ diff.inspect }"
            end
            r = [
              diff.first, # type of modification
              diff.last, # diff string
              "line #{ line_num }",
              excerpt
            ]
            if [0,-1].include?(diff.first)
              # only count chars and newlines in identical or deletions since all info
              # refers to string_1
              char_num += diff.last.length
              line_num += diff.last.count('\n')
            end
            r
          }
          deltas = deltas.find_all { |e| 0 != e.first }
        end
      end

    end
  end
end
