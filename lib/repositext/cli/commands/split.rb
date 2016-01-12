class Repositext
  class Cli
    module Split

    private

      # Updates the subtitle_mark character positions in *.subtitle_markers.csv
      # in /content
      def split_subtitles(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Splitting subtitles",
          options.merge(
            use_new_repositext_file_api: true,
            repository: repository,
          )
        ) do |repositext_file|
          outcome = Repositext::Process::Split::Subtitles.new(
            repositext_file,
            repositext_file.corresponding_primary_file
          ).split
          [Outcome.new(outcome.success, { contents: outcome.result })]
        end
      end

      def split_test(options)
        # dummy method for testing
        puts 'split_test'
      end

    end
  end
end
