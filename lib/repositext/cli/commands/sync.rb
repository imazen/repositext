class Repositext
  class Cli
    module Sync

    private

      # Updates the subtitle_mark character positions in *.subtitle_markers.csv
      # in /content
      def sync_subtitle_mark_character_positions(options)
        Repositext::Cli::Utils.convert_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          /\.at\z/i,
          "Syncing subtitle_mark character positions from *.at to *.subtitle_markers.csv",
          options.merge(input_is_binary: false)
        ) do |contents, filename|
          if !contents.index('@')
            # Don't create a new subtitle_markers CSV file for contents that don't
            # contain any subtitle_marks
            []
          else
            # this contents contains subtitle_markers
            stm_csv_path = filename.gsub(/\.at\z/, '.subtitle_markers.csv')
            previous_stm_csv = if File.exists?(stm_csv_path)
              File.read(stm_csv_path)
            else
              nil
            end
            outcome = Repositext::Sync::SubtitleMarkCharacterPositions.sync(
              contents, previous_stm_csv
            )
            [Outcome.new(true, { contents: outcome.result, extension: 'subtitle_markers.csv' })]
          end
        end
      end

      def sync_test(options)
        # dummy method for testing
        puts 'sync_test'
      end

    end
  end
end
