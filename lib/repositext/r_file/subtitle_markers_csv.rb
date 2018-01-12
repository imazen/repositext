class Repositext
  class RFile

    # Represents a Subtitle marker CSV file in repositext.
    class SubtitleMarkersCsv < Csv

      include FollowsStandardFilenameConvention
      include HasCorrespondingContentAtFile
      include HasCorrespondingPrimaryContentAtFile
      include HasCorrespondingPrimaryFile

      # Returns an array of the contained subtitles
      # @return [Array<Repositext::Subtitle>]
      def subtitles
        idx = 0
        current_record_id = nil
        csv.to_a.map { |row|
          new_record_id = row['recordId']
          is_record_boundary = (new_record_id != current_record_id)
          current_record_id = new_record_id
          Subtitle.new({
            relative_milliseconds: row['relativeMS'],
            samples: row['samples'],
            char_length: row['charLength'],
            persistent_id: row['persistentId'],
            record_id: new_record_id,
            tmp_attrs: { index: idx += 1,
                         is_record_boundary: is_record_boundary },
          })
        }
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
