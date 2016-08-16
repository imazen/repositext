class Repositext
  class Repository
    module HasDataJsonFile

      extend ActiveSupport::Concern

      # Returns the corresponding data.json file.
      # @return [RFile]
      def corresponding_data_json_file
        if !File.exist?(corresponding_data_json_filename)
          raise "data.json file does not exist: #{ corresponding_data_json_filename }"
        end
        RFile::DataJson.new(
          File.read(corresponding_data_json_filename),
          Language.new,
          corresponding_data_json_filename,
        )
      end

      # Finds the corresponding data.json file if self is a content AT file.
      def corresponding_data_json_filename
        File.join(base_dir, 'data.json')
      end

      # Returns all key value pairs of corresponding data_json file
      # under the 'data' key as Hash
      def read_repo_level_data
        cdjf = corresponding_data_json_file
        return {}  if cdjf.nil?
        cdjf.read_repo_level_data
      end

      # Syncs key_val_pairs under data key in corresponding data_json file.
      # @param key_val_pairs [Hash] with string keys
      def update_repo_level_data(key_val_pairs)
        # Create corresponding data.json file if it doesn't exist yet
        cdjf = corresponding_data_json_file
        cdjf.update_data!(key_val_pairs)
      end
    end
  end
end
