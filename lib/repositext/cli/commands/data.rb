class Repositext
  class Cli
    # This namespace contains methods related to the `data` command.
    module Data

    private

      # Sets the `st_sync_active` key to false in any data.json files that match
      # file-selector. NOTE: You can specify it using either --dc or --file-selector
      # command line arguments.
      # @param options [Hash]
      def data_set_st_sync_active_to_false(options)
        if '' == options['file-selector'].to_s.strip
          raise(ArgumentError.new("You must provide the file-selector command line option for this command!"))
        end
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            :content_dir,
            options['file-selector'],
            :json_extension
          ),
          /\.data\.json\z/,
          "Setting `st_sync_active` to false",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |data_json_file|
          new_contents = data_json_file.update_settings('st_sync_active' => false)
          [Outcome.new(true, { contents: new_contents })]
        end
      end

    end
  end
end
