class Repositext
  class Cli
    # This namespace contains methods related to the `delete` command.
    module Delete

    private

      # Deletes all contents inside directory_path
      # @param options [Hash] expects :directory_path key
      def delete_directory_contents(options)
        if options[:directory_path].nil?
          raise ":directory_path option is required"
        end
        puts "Deleting all files under #{ options[:directory_path] }"
        FileUtils.rm_rf(
          Dir.glob("#{ options[:directory_path] }/*"),
          secure: true
        )
      end

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

      # Deletes all PDF export files in repo.
      def delete_all_pdf_exports(options)
        delete_options = options.dup
        # Force file-selector to all files.
        delete_options['file-selector'] = "**/*"

        delete_pdf_exports(delete_options)
      end

      # Deletes PDF export files that match file-selector.
      # Requires the 'file-selector' option to be present
      def delete_pdf_exports(options)
        delete_options = options.dup
        # Force base-dir and file-extension to PDF export, leave file-selector as is
        delete_options['base-dir'] = :pdf_export_dir
        delete_options['file-extension'] = :pdf_extension

        delete_files(delete_options)
      end

    end
  end
end
