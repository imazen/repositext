class Repositext
  class Subtitle
    class ExtractFromStmCsvFile

      # @param stm_csv_file [RFile, nil]
      def initialize(stm_csv_file)
        @stm_csv_file = stm_csv_file
      end

      # Returns an array of subtitle objects
      # @return [Array<Subtitle>]
      def extract
        return []  if @stm_csv_file.nil?
        csv = CSV.new(
          @stm_csv_file.contents,
          col_sep: "\t",
          headers: :first_row
        )
        subtitles = csv.to_a.map { |row|
          r = row.to_hash
          Subtitle.new({
            relative_milliseconds: r['relativeMS'],
            samples: r['samples'],
            char_length: r['charLength'],
            persistent_id: r['persistentId'],
            record_id: r['recordId'],
          })
        }
      end

    end
  end
end
