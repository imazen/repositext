class Repositext
  class Services

    # Returns the number of subtitle_marks in stm_csv
    #
    class ExtractSubtitleMarkCountStmCsv

      # @param stm_csv [String] the CSV file contents
      # @return [Integer]
      def self.call(stm_csv)
        stm_csv.strip.count("\n")
      end

    end
  end
end
