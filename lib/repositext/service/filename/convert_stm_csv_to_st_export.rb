class Repositext
  class Service
    class Filename
      # Converts subtitle marker CSV file name to format used for subtitle export.
      # Example:
      #   /path/eng65-0403_1234.subtitle_markers.csv => /path/65-0403_1234.markers.txt
      class ConvertStmCsvToStExport

        # @param attrs [Hash{Symbol => Object}]
        # @option attrs [String] :source_filename absolute path
        # @return [Hash{result: String}]
        def self.call(attrs)
          {
            result: attrs[:source_filename].sub(
              /\/[[:alpha:]]{3}([^\/\.]+)\.subtitle_markers\.csv/,
              '/\1.markers.txt'
            ),
          }
        end

      end
    end
  end
end
