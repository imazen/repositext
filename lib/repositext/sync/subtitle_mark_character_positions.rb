class Repositext
  class Sync
    class SubtitleMarkCharacterPositions

      # Synchronizes subtitle_mark character positions from content_at into
      # content *.subtitle_markers.csv.
      # Creates the csv file if it doesn't exist already.
      # @param[String] content_at current content_at text
      # @param[String, nil] existing_stm_csv an existing CSV file, or nil if none exists
      # @return[Outcome] the sync'd csv string is returned as #result if successful.
      def self.sync(content_at, existing_stm_csv)
        # Compute new stm_positions
        new_stm_positions_and_lengths = Repositext::Utils::SubtitleMarkTools.extract_captions(content_at)
        # Prepare temporary CSV array with correct number of data rows, no headers
        tmp_csv_array = if existing_stm_csv
          # Load existing CSV, extract existing vals
          csv = CSV.new(existing_stm_csv, col_sep: "\t", headers: :first_row)
          csv.to_a.map { |row|
            r = row.to_hash
            Repositext::Utils::SubtitleMarkTools.csv_headers.map { |header| r[header] }
          }
        else
          # No existing CSV, create an array with correct number of (empty) rows
          new_stm_positions_and_lengths.map { |e| [] }
        end
        # make sure that both counts are identical
        if new_stm_positions_and_lengths.length != tmp_csv_array.length
          # TODO: maybe we have to make them the same length, if stm was added or removed
          raise "Different counts: #{ tmp_csv_array.length } -> #{ new_stm_positions_and_lengths.length }"
        end
        # merge new positions and lengths into existing array
        merged_csv_array = tmp_csv_array.each_with_index.map { |existing_row, idx|
          new_row = new_stm_positions_and_lengths[idx]
          [
            existing_row[0], # 'relativeMS' from existing CSV
            existing_row[1], # 'samples' from existing CSV
            new_row[:char_pos], # 'charPos' from new_stm_positions_and_lengths
            new_row[:char_length], # 'charLength' from new_stm_positions_and_lengths
          ]
        }
        # Convert to CSV
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
