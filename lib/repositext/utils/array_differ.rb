class Repositext
  class Utils
    class ArrayDiffer

      # @param a1 [Array]
      # @param a2 [Array]
      # @return [Array]
      def self.diff(a1, a2)
        Diff::LCS.sdiff(a1, a2)
      end

    end
  end
end
