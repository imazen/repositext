class Repositext
  class RFile

    # Represents a CSV file in repositext.
    class Csv < RFile

      # Options to be used when reading or writing CSV
      def self.csv_options
        { col_sep: "\t", headers: :first_row }
      end

      # Returns contents as CSV object.
      # Important: This uses the current value of #contents (rather than
      # reloading from disk!) so that this also works when we call, e.g.,
      # `#subtitles` on an StmCsvFile that is checked out at a certain git commit.
      def csv
        CSV.new(contents, self.class.csv_options)
      end

      # Yields each row as hash with stringified keys to block
      def each_row
        csv.each do |row|
          # row: #<CSV::Row "relativeMS":"6223" "samples":"151367170" "charLength":"34" "persistentId":"4498439" "recordId":"55020559">
          yield(row)
        end
      end

    end
  end
end
