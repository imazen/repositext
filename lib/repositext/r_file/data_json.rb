class Repositext
  class RFile
    # Represents a .data.json file in repositext.
    class DataJson < RFile

      include FollowsStandardFilenameConvention
      include HasCorrespondingContentAtFile
      include HasCorrespondingPrimaryContentAtFile
      include HasCorrespondingPrimaryFile

      # Creates an empty data.json file. Raises an error if the file already
      # exists.
      # @param filename
      def self.create_empty_data_json_file!(filename)
        if File.exist?(filename)
          raise "File `#{ filename }` already exists!"
        end
        File.write(filename, default_file_contents)
      end

      # Returns the default contents for a data.json file
      # @return [String] JSON formatted string
      def self.default_file_contents
        JSON.generate(default_data, JSON_FORMATTING_OPTIONS) + "\n"
      end

      # Returns default data as Hash
      def self.default_data
        { 'data' => {}, 'settings' => {} }
      end

      # Returns all key value pairs as hash
      def get_all_attributes
        (JSON.parse(contents) || self.class.default_data)
      end

      def read_data
        get_all_attributes['data'] || {}
      end

      def read_settings
        get_all_attributes['settings'] || {}
      end

      # Merges key_val_pairs into existing data and returns the resulting
      # update JSON representation.
      # @param key_val_pairs [Hash] with string keys
      # @return [String] the entire updated contents as JSON string
      def update_data(key_val_pairs)
        # merge key_val_pairs under 'data' key
        new_contents = get_all_attributes
        new_contents['data'] ||= {}
        new_contents['data'].merge!(key_val_pairs)
        JSON.generate(new_contents, JSON_FORMATTING_OPTIONS) + "\n"
      end

      # Updates key_val_pairs under the 'data' key in self.
      # @param key_val_pairs [Hash] with string keys
      def update_data!(key_val_pairs)
        lock_self_exclusively do
          # merge key_val_pairs under 'data' key and write file back to disk
          File.write(filename, update_data(key_val_pairs))
        end
      end

      # Merges key_val_pairs into existing settings and returns the resulting
      # update JSON representation.
      # @param key_val_pairs [Hash] with string keys
      # @return [String] the entire updated contents as JSON string
      def update_settings(key_val_pairs)
        # merge key_val_pairs under 'settings' key
        new_contents = get_all_attributes
        new_contents['settings'] ||= {}
        new_contents['settings'].merge!(key_val_pairs)
        JSON.generate(new_contents, JSON_FORMATTING_OPTIONS) + "\n"
      end

      # Updates key_val_pairs under the 'settings' key in self.
      # @param key_val_pairs [Hash] with string keys
      def update_settings!(key_val_pairs)
        lock_self_exclusively do
          # merge key_val_pairs under 'settings' key and write file back to disk
          File.write(filename, update_settings(key_val_pairs))
        end
      end
    end
  end
end
