class Repositext
  class Cli
    # This namespace contains methods related to the `sync` command.
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
            use_new_r_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          content_at_file.update_file_level_data!(key_val_pairs)
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
            use_new_r_file_api: true,
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

      # Procedure for syncing subtitles while we do this manually on command line:
      # * create branch
      # * import subtitles
      # * commit changes to subtitles
      # * merge branch into master
      # * check out master
      # * run rt sync subtitles on primary repo
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
            'is_initial_primary_sync' => false,
            'last_operation_id' => primary_repo.read_repo_level_data['st_sync_last_operation_id'],
            'primary_repository' => primary_repo,
            'stids_inventory_file' => stids_inventory_file,
          )
        ).sync
      end

      # Synchronizes subtitles in foreign files that match options['file-selector'].
      # This is called from `import_subtitle` when run on foreign repos.
      # It transfers any subtitle operations that have accumulated since the
      # foreign file's subtitles were exported.
      def sync_subtitles_for_foreign_files(options)
        if config.setting(:is_primary_repo)
          raise "This command can only be used in a foreign repository."
        end

        file_count = 0
        primary_content_type = content_type.corresponding_primary_content_type
        primary_config = primary_content_type.config
        primary_repo = primary_content_type.repository
        primary_repo_sync_commit = primary_repo.read_repo_level_data['st_sync_commit']

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
            use_new_r_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          file_count += 1
          # We want to sync the foreign file to the current primary
          # st_sync_commit.
          # NOTE: This process updates the file level st_sync data for
          # `st_sync_commit` and `st_sync_subtitles_to_review` for content_at_file.
          method_args = {
            'config' => primary_config,
            'primary_repository' => primary_repo,
            'to-commit' => primary_repo_sync_commit
          }
          # We use this method as part of subtitle import to re-apply any pending
          # st_ops since the subtitle export. We accomplish this by providing
          # the 'from-commit' option with the value of the export git commit:
          if options['re-apply-st-ops-since-st-export']
            # During the subtitle import we copied the value of
            # `exported_subtitles_at_st_sync_commit` to `st_sync_commit`, and
            # then we set `exported_subtitles_at_st_sync_commit` to null.
            # So at this point we have to read the export commit from `st_sync_commit`.
            export_commit = content_at_file.read_file_level_data['st_sync_commit']
            if '' == export_commit.to_s.strip
              raise "Missing `st_sync_commit` (effective export git commit), can't re-apply st_ops since st export!"
            end
            method_args['from-commit'] = export_commit
          end
          sync_sts = Repositext::Process::Sync::Subtitles.new(method_args)
          sync_sts.sync_foreign_file(content_at_file)
        end
      end

      def sync_test(options)
        # dummy method for testing
        puts 'sync_test'
      end

    end
  end
end
