class Repositext
  class Cli
    module Move

    private

      def move_staging_to_content(options)
        input_file_spec = options['input'] || 'staging_dir/at_files'
        input_base_dir_name, input_file_pattern_name = input_file_spec.split(
          Repositext::Cli::FILE_SPEC_DELIMITER
        )
        output_base_dir = options['output'] || config.base_dir(:content_dir)

        Repositext::Cli::Utils.move_files(
          config.base_dir(input_base_dir_name),
          config.file_pattern(input_file_pattern_name),
          output_base_dir,
          /\.at\z/,
          "Moving AT files from /staging to /content",
          options
        )
      end

    end
  end
end
