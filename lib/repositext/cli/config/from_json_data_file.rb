# Loads settings from Json Data file
class Repositext
  class Cli
    class Config
      # Loads Cli::Config from a *.json.data file.
      class FromJsonDataFile

        # @param json_data_file_path
        def initialize(json_data_file_path)
          @json_data_file_path = json_data_file_path
        end

        # @param json_string_override [String] for testing
        def load(json_string_override=nil)
          JSON.load(
            json_string_override || File.read(@json_data_file_path)
          )['settings']
        end

      end
    end
  end
end
