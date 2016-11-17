class Repositext
  class Cli
    # This namespace contains methods related to the sync command.
    module Sync

    private

      # Given file specifications for content AT files, this command updates
      # key value pairs under each corresponding `data.json` file's 'data' key.
      # This command will create any missing `data.json` files.
      # @param options [Hash] with file specifications for content AT files.
      # @param key_val_pairs [Hash] will be merged under the 'data' key
      def sync_file_level_data(options, key_val_pairs)
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          nil,
          "syncing file level data",
          options.merge(
            use_new_repositext_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          content_at_file.update_file_level_data(key_val_pairs)
        end

      end

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
            outcome = Repositext::Process::Sync::SubtitleMarkCharacterPositions.sync(
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
            content_type: content_type,
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

      def sync_subtitles(options)
        if !config.setting(:is_primary_repo)
          raise "Please run this command from inside the primary repository"
        end
        # Compute options for extracting subtitles
        file_list_pattern = config.compute_glob_pattern(
          options['base-dir'] || :content_dir,
          :all_files, # NOTE: We can't allow file-selector since this would result in an incomplete st-ops file
          options['file-extension'] || :at_extension
        )
        file_list = Dir.glob(file_list_pattern)
        if (file_filter = options['file_filter'])
          file_list = file_list.find_all { |filename| file_filter === filename }
        end
        stids_inventory_file = File.open(
          File.join(config.base_dir(:data_dir), 'subtitle_ids.txt'),
          'r+'
        )
        primary_repo = content_type.repository
        Process::Sync::Subtitles.new(
          options.merge(
            'config' => config,
            'file_list' => file_list,
            'is_initial_sync' => true,
            'last_operation_id' => primary_repo.read_repo_level_data['st_sync_lastest_operation_id'],
            'primary_repository' => primary_repo,
            'stids_inventory_file' => stids_inventory_file,
          )
        ).sync
      end

      def sync_test(options)
        # dummy method for testing
        puts 'sync_test'
      end

    end
  end
end
