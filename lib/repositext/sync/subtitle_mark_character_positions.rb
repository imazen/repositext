class Repositext
  class Sync
    # Synchronizes subtitle_mark character lengths from content_at into
    # content *.subtitle_markers.csv.
    # Creates the csv file if it doesn't exist already.
    class SubtitleMarkCharacterPositions

      # @param content_at [String] current content_at text
      # @param existing_stm_csv [String, nil] an existing CSV file, or nil if none exists
      # @param auto_insert_missing_subtitle_marks [Boolean] set to true to
      #     automatically insert missing subtitle marks into subtitle_marker
      #     files based on subtitles in /content AT.
      # @return [Outcome] the sync'd csv string is returned as #result if successful.
      def self.sync(content_at, existing_stm_csv, auto_insert_missing_subtitle_marks)
        # Compute new stm_positions
        new_stm_lengths = Repositext::Utils::SubtitleMarkTools.extract_captions(content_at)
        # Prepare temporary CSV array with correct number of data rows, no headers
        # TODO STID: Keep STIDs
        # TODO STID: check for meaning of auto_insert_missing_subtitle_marks and this if/else construct
        tmp_csv_array = if existing_stm_csv && !auto_insert_missing_subtitle_marks
          # Load existing CSV, extract existing vals
          csv = CSV.new(existing_stm_csv, col_sep: "\t", headers: :first_row)
          csv.to_a.map { |row|
            r = row.to_hash
            Repositext::Utils::SubtitleMarkTools.csv_headers.map { |header| r[header] }
          }
        else
          # No existing CSV, create an array with correct number of rows.
          # Sets relativeMS and samples to 0,
          # Sets relativeMS, samples, and charLength to 0
          # Sets subtitleId and recordId to nil
          new_stm_lengths.map { |e| [0,0,0,nil,nil] }
        end
        # make sure that both counts are identical
        if new_stm_lengths.length != tmp_csv_array.length
          raise "Different counts: #{ tmp_csv_array.length } -> #{ new_stm_lengths.length }"
        end
        # merge new positions and lengths into existing array
        merged_csv_array = tmp_csv_array.each_with_index.map { |existing_row, idx|
          new_row = new_stm_lengths[idx]
          [
            existing_row[0], # 'relativeMS' from existing CSV
            existing_row[1], # 'samples' from existing CSV
            new_row[:char_length], # 'charLength' from new_stm_lengths
            existing_row[3], # 'subtitleId' from existing CSV
            existing_row[4], # 'recordId' from existing CSV
          ]
        }
        # Convert to CSV
        # TODO: Use new RFile::SubtitleMarkerCsv class for this!
        csv_string = CSV.generate(col_sep: "\t") do |csv|
          csv << Repositext::Utils::SubtitleMarkTools.csv_headers
          merged_csv_array.each do |row|
            csv << row
          end
        end

        Outcome.new(true, csv_string)
      end

    end
  end
end
