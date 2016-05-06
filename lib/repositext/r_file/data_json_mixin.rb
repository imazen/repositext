class Repositext
  class RFile

    # Contains code that is specific to `data.json` files
    module DataJsonMixin
      # Returns the corresponding data.json file. Can create if it doesn't exist.
      # @param create_if_it_doesnt_exist [Boolean, Optional] default: false
      # @return [RFile]
      def corresponding_data_json_file(create_if_it_doesnt_exist=false)
        if !File.exist?(corresponding_data_json_filename)
          if create_if_it_doesnt_exist
            create_data_json_file!(corresponding_data_json_filename)
          else
            return nil
          end
        end
        RFile::Text.new(
          File.read(corresponding_subtitle_markers_csv_filename),
          language,
          corresponding_subtitle_markers_csv_filename,
          content_type
        )
      end

      def corresponding_data_json_filename
        filename.sub(/\.at\z/, '.data.json')
      end

      # Creates an empty data.json file. Raises an error if the file already
      # exists.
      # @param filename
      def create_data_json_file!(filename)
        if File.exist?(filename)
          raise "File `#{ filename }` already exists!"
        end
        File.write(
          filename,
          data_json_file_default_contents
        )
      end

      # Returns the default contents for a data.json file
      def data_json_file_default_contents
        JSON.dump({ data: {}, settings: {}, subtitles: {} })
      end

      def sync_file_level_data(key_val_pairs)
        # Create corresponding data.json file if it doesn't exist yet

        # merge key_val_pairs under 'data' key
        # write data.json file back to disk
      end

    end
  end
end
