class Repositext
  class RFile

    # Represents a Subtitle marker CSV file in repositext.
    class SubtitleMarkersCsv < RFile

      include FollowsStandardFilenameConvention
      include HasCorrespondingContentAtFile
      include HasCorrespondingPrimaryContentAtFile
      include HasCorrespondingPrimaryFile

      # Options to be used when reading or writing CSV
      def self.csv_options
        { col_sep: "\t", headers: :first_row }
      end

      # Returns an array of the contained subtitles
      # @param [Array<Repositext::Subtitle>]
      def subtitles
        csv.to_a.map { |row|
          Subtitle.new({
            relative_milliseconds: row['relativeMS'],
            samples: row['samples'],
            char_length: row['charLength'],
            persistent_id: row['persistentId'],
            record_id: row['recordId'],
          })
        }
      end

      # Returns contents as CSV object
      def csv
        csv = CSV.new(contents, self.class.csv_options)
      end

    end
  end
end
