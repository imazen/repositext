class Repositext
  class Cli
    module Move

    private

      def move_staging_to_master(options)
        input_file_pattern = options[:input] || config.file_pattern(:staging_at)
        output_file_pattern = options[:output] || config.file_pattern(:master)
        output_base_dir = Repositext::Cli::Utils.base_dir_from_glob_pattern(output_file_pattern)
        file_filter = /\.at\z/
        description = "Moving AT files from staging to master"

        Repositext::Cli::Utils.move_files(
          input_file_pattern, output_base_dir, file_filter, description, options
        )
      end

    end
  end
end
