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
      def self.default_file_contents
        JSON.generate(
          { data: {}, settings: {}, subtitles: {} },
          json_formatting_options
        )
      end

      def self.json_formatting_options
        {
          indent: '  ',
          space: '',
          space_before: '',
          object_nl: "\n",
          array_nl: "\n",
          allow_nan: false,
          max_nesting: 100,
        }
      end

      # Returns all key value pairs under the 'data' key as Hash
      def get_file_level_data
        (JSON.load(contents) || {'data' => {}})['data']
      end

      # @param key_val_pairs [Hash] with string keys
      def sync_file_level_data(key_val_pairs)
        # merge key_val_pairs under 'data' key
        new_data = get_file_level_data.merge(key_val_pairs)
        # write file back to disk
        File.write(filename, new_data)
      end
    end
  end
end
