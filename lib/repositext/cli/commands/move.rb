class Repositext
  class Cli
    module Move

    private

      def move_staging_to_content(options)
        input_base_dir = config.compute_base_dir(options['base-dir'] || :staging_dir)
        input_file_selector = config.compute_file_selector(options['file-selector'] || :all_files)
        input_file_extension = config.compute_file_extension(options['file-extension'] || :at_extension)
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        Repositext::Cli::Utils.move_files(
          input_base_dir,
          input_file_selector,
          input_file_extension,
          output_base_dir,
          options['file_filter'],
          "Moving AT files from /staging to /content",
          options
        )
      end

    end
  end
end
