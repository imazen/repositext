class Repositext
  class Cli
    module Distribute

    private

      # Adds the title to the filename
      def distribute_add_title_to_filename(options)
        Repositext::Cli::Utils.rename_files(
          options[:input_base_dir],
          options[:input_file_selector],
          options[:input_file_extension],
          options[:file_rename_proc],
          options['file_filter'],
          "Renaming files",
          options
        )
      end

    end
  end
end
