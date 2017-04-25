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

      # Yields each row as hash with stringified keys to block
      def each_row
        csv.each do |row|
          # row: #<CSV::Row "relativeMS":"6223" "samples":"151367170" "charLength":"34" "persistentId":"4498439" "recordId":"55020559">
          yield(row)
        end
      end

      # Returns an array of the contained subtitles
      # @return [Array<Repositext::Subtitle>]
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

      # Returns contents as CSV object.
      # Important: This uses the current value of #contents (rather than
      # reloading from disk!) so that this also works when we call, e.g.,
      # `#subtitles` on an StmCsvFile that is checked out at a certain git commit.
      def csv
        csv = CSV.new(contents, self.class.csv_options)
      end

      # @param new_subtitle_markers_data [Array<Hash>]
      #    [
      #      {
      #        relative_milliseconds: 123,
      #        samples: 123,
      #        charLength: 123,
      #        persistentId: 123,
      #        recordId: 123,
      #      }
      #    ]
      def update!(new_subtitle_markers_data)
        csv_string = CSV.generate(col_sep: "\t") do |csv|
          csv << Repositext::Utils::SubtitleMarkTools.csv_headers
          new_subtitle_markers_data.each do |st_attrs|
            csv << [
              st_attrs[:relative_milliseconds],
              st_attrs[:samples],
              st_attrs[:char_length],
              st_attrs[:persistent_id],
              st_attrs[:record_id],
            ]
          end
        end
        File.write(filename, csv_string)
      end

    end
  end
end
