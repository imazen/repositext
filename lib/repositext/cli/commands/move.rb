class Repositext
  class Cli
    module Move

    private

      def move_staging_to_master(options)
        input_file_spec = options[:input] || 'staging_dir.at_files'
        output_base_dir = options[:output] || config.base_dir(:master_dir)
        input_base_dir, input_file_pattern = input_file_spec.split('.')

        Repositext::Cli::Utils.move_files(
          input_base_dir,
          input_file_pattern,
          output_base_dir,
          /\.at\z/,
          "Moving AT files from staging to master",
          options
        )
      end

    end
  end
end
