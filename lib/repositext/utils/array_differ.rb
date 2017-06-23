class Repositext
  class Utils
    # Generates a diff of two serialized Arrays.
    class ArrayDiffer

      # Example:
      #     a1 = %w[a b c   e f]
      #     a2 =     %w[c d e f g h]
      #     r = Repositext::Utils::ArrayDiffer.diff(a1, a2)
      #     => [["-", [0, "a"], [0, nil]],
      #         ["-", [1, "b"], [0, nil]],
      #         ["=", [2, "c"], [0, "c"]],
      #         ["+", [3, nil], [1, "d"]],
      #         ["=", [3, "e"], [2, "e"]],
      #         ["=", [4, "f"], [3, "f"]],
      #         ["+", [5, nil], [4, "g"]],
      #         ["+", [5, nil], [5, "h"]]]
      # @param a1 [Array]
      # @param a2 [Array]
      # @return [Array]
      def self.diff(a1, a2)
        Diff::LCS.sdiff(a1, a2)
      end

      # Returns a simplified diff output
      # Example:
      #     a1 = %w[a b c   e f]
      #     a2 =     %w[c d e f g h]
      #     r = Repositext::Utils::ArrayDiffer.diff(a1, a2)
      #     => [["-", "a"],
      #         ["-", "b"],
      #         ["+", "d"],
      #         ["+", "g"],
      #         ["+", "h"]]
      def self.diff_simple(a1, a2)
        diff(a1, a2).map { |e|
          op, e1, e2 = e.to_a # Cast Diff::LCS::ContextChange to Array
          next nil  if '=' == op
          [op, [e1.last, e2.last].compact.first]
        }.compact
      end

    end
  end
end
