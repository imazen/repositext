class Repositext
  class RFile
    # Include this module in any RFile subclass that has a corresponding data.json file.
    module HasCorrespondingDataJsonFile

      extend ActiveSupport::Concern

      # Returns the corresponding data.json file. Can create if it doesn't exist.
      # @param create_if_it_doesnt_exist [Boolean, Optional] default: false
      # @return [RFile]
      def corresponding_data_json_file(create_if_it_doesnt_exist=false)
        if !File.exist?(corresponding_data_json_filename)
          if create_if_it_doesnt_exist
            DataJson.create_empty_data_json_file!(corresponding_data_json_filename)
          else
            return nil
          end
        end
        RFile::DataJson.new(
          File.read(corresponding_data_json_filename),
          language,
          corresponding_data_json_filename,
          content_type
        )
      end

      # Finds the corresponding data.json file if self is a content AT file.
      def corresponding_data_json_filename
        raise "This only works for content AT files!"  if filename !~ /\.at\z/
        filename.sub(/\.at\z/, '.data.json')
      end

      # Returns all key value pairs of corresponding data_json file
      # under the 'data' key as Hash with stringified keys.
      def read_file_level_data
        cdjf = corresponding_data_json_file
        return {}  if cdjf.nil?
        cdjf.read_data
      end

      # Returns all key value pairs of corresponding data_json file
      # under the 'settings' key as Hash with stringified keys.
      def read_file_level_settings
        cdjf = corresponding_data_json_file
        return {}  if cdjf.nil?
        cdjf.read_settings
      end

      # Syncs key_val_pairs under data key in corresponding data_json file.
      # @param key_val_pairs [Hash] with string keys
      def update_file_level_data(key_val_pairs)
        # Create corresponding data.json file if it doesn't exist yet
        cdjf = corresponding_data_json_file(true)
        cdjf.update_data!(key_val_pairs)
      end
    end
  end
end
