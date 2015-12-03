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
          if contents.index('@')
            # This file contains subtitle_marks: Create subtitle_markers CSV file.
            stm_csv_path = filename.gsub(/\.at\z/, '.subtitle_markers.csv')
            previous_stm_csv = if File.exists?(stm_csv_path)
              File.read(stm_csv_path)
            else
              nil
            end
            outcome = Repositext::Sync::SubtitleMarkCharacterPositions.sync(
              contents,
              previous_stm_csv,
              options['auto-insert-missing-subtitle-marks']
            )
            [Outcome.new(true, { contents: outcome.result, extension: 'subtitle_markers.csv' })]
          else
            # File doesn't contain subtitle_marks:
            # Don't create a new subtitle_markers CSV file.
            []
          end
        end
      end

      # Updates symlinks to corresponding subtitle marker csv files in foreign
      # language repos. Only symlinks those files that have an entry in
      # erp_data in the foreign language.
      def sync_subtitle_marker_csv_file_symlinks(options)
        erp_data_json_filename = File.join(config.base_dir(:data_dir), 'erp_data.json')
        erp_api = Vgr::ErpApi.new(erp_data_json_filename)
        results = []
        file_count = 0
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options.merge(
            use_new_repositext_file_api: true,
            repository: repository,
          )
        ) do |content_at_file|
          file_count += 1
          # Determine if we want symlink or not: Only if erp data for the file is present.
          file_erp_data_present = erp_api.get_product_data(
            content_at_file.extract_product_identity_id,
            false
          ).present?
          outcome = Repositext::Process::Sync::SubtitleMarkerCsvFileSymlinks.new(
            content_at_file,
            file_erp_data_present
          ).sync
          results << outcome.result
        end
        results.compact! # remove no-ops
        lines = [
          "Synchronize subtitle_marker CSV file symlinks",
          '-' * 40,
          '',
        ]
        if results.empty?
          lines << "No symlinks required an update."
        else
          lines << "The following #{ results.length } symlinks were updated:"
          results.each do |r|
            lines << " - #{ r }"
          end
        end
        lines << '-' * 40
        lines << "Updated #{ results.length } symlinks of #{ file_count } total files at #{ Time.now.to_s }."
        $stderr.puts
        lines.each { |l| $stderr.puts l }
      end

      def sync_test(options)
        # dummy method for testing
        puts 'sync_test'
      end

    end
  end
end
