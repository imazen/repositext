class Repositext
  class Cli
    module Delete

    private

      # Delete files that match file specs.
      # @param options [Hash]
      def delete_files(options)
        if '' == options['base-dir'].to_s
          raise ArgumentError.new("Missing options['base-dir']")
        end
        if '' == options['file-selector'].to_s
          raise ArgumentError.new("Missing options['file-selector']")
        end
        if '' == options['file-extension'].to_s
          raise ArgumentError.new("Missing options['file-extension']")
        end
        input_base_dir = config.compute_base_dir(options['base-dir'])
        input_file_selector = config.compute_file_selector(options['file-selector'])
        input_file_extension = config.compute_file_extension(options['file-extension'])

        Repositext::Cli::Utils.delete_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          options['file_filter'],
          "Deleting files",
          {}
        )
      end

    end
  end
end
