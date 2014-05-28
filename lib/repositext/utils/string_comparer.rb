class Repositext
  class Utils
    # Compares strings and returns diffs
    class StringComparer

      # Compares string_1 with string_2 using diff_match_patch.
      # @param[String] string_1
      # @param[String] string_2
      # @return[Array] An array of diffs like so:
      # [[1, 'added'], [-1, 'removed']]
      def self.compare(string_1, string_2)
        if string_1 == string_2
          return []
        else
          diff = Suspension::DiffAlgorithm.new.call(string_1, string_2)
          deltas = diff.find_all { |e| 0 != e.first }
        end
      end

    end
  end
end
