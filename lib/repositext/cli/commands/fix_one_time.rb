class Repositext
  class Cli
    # This namespace contains methods related to the `fix` command (one-time fixes).
    module Fix

    private

      # Adds `.first_par` class to all first paragraphs in content AT files.
      # This script can be run multiple times on all repos.
      # Use like so:
      # > bundle console
      # parent_path = "/Users/x/repositext_parent"
      # %w[general].each do |content_type_name|
      #   puts "Content type: #{ content_type_name }"
      #   Repositext::RepositorySet.new(parent_path).run_repositext_command(
      #     :primary_repo,
      #     "rt #{ content_type_name } fix add_first_par_class"
      #   )
      # end
      def fix_add_first_par_class(options)
        first_block_level_ial_regex = /(?<=^\{: )[^\}]+(?=\s*\}\n)/
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Adding .first_par classes",
          options.merge(
            use_new_r_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          new_contents = content_at_file.contents.dup
          # skip if already added
          if new_contents.index('.first_par')
            puts "   - skip"
            next []
          end
          # Add .first_par class to first block level IAL in file
          new_contents.sub!(first_block_level_ial_regex, '.first_par \0')
          [Outcome.new(true, { contents: new_contents })]
        end
      end


      # Adds initial persistent subtitle ids and record ids to
      # subtitle_marker.csv files.
      # This should only be run once on the primary repo.
      def fix_add_initial_persistent_subtitle_ids(options)
        spids_inventory_file = File.open(
          File.join(config.base_dir(:data_dir), 'subtitle_ids.txt'),
          'r+'
        )
        if spids_inventory_file.read.present?
          # We expect inventory file to be empty when we run this command
          raise ArgumentError.new("SPID inventory file is not empty!")
        end

        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :csv_extension
          ),
          options['file_filter'] || /\.subtitle_markers\.csv\z/i,
          "Adding initial persistent subtitle ids",
          options.merge(
            use_new_r_file_api: true,
            content_type: content_type,
          )
        ) do |stm_csv_file|
          ccafn = stm_csv_file.filename.sub('.subtitle_markers.csv', '.at')
          corresponding_content_at_file = RFile::ContentAt.new(
            File.read(ccafn),
            stm_csv_file.language,
            ccafn
          )
          outcome = Repositext::Process::Fix::AddInitialPersistentSubtitleIds.new(
            stm_csv_file,
            corresponding_content_at_file,
            spids_inventory_file
          ).fix
          [Outcome.new(outcome.success, { contents: outcome.result })]
        end
      end

      # Makes sure that every content AT file in the repo has a corresponding
      # data.json file.
      # This should be run once on all language repos
      # @param options [Hash] accepts 'data_json_settings' key with a Hash
      #   to determine any data that should be merged into the 'settings' key.
      #   Keys must be stringified.
      def fix_add_initial_data_json_file(options)
        Repositext::Cli::Utils.read_files(
          config.compute_glob_pattern(
            :content_dir,
            options['file-selector'] || :all_files,
            :at_extension
          ),
          options['file_filter'],
          nil,
          "Reading content AT files",
          options.merge(
            use_new_r_file_api: true,
            content_type: content_type,
          )
        ) do |content_at_file|
          # We first check to see if djf exists already. If so, we don't apply
          # initial_only_data_json_settings.
          if content_at_file.corresponding_data_json_file.nil?
            # djf does not exist. Create it by calling
            # `corresponding_data_json_file(true)`. We also apply any
            # `initial_only_data_json_settings`.
            djf = content_at_file.corresponding_data_json_file(true)
            if options['initial_only_data_json_settings']
              djf.update_settings!(options['initial_only_data_json_settings'])
            end
          end
        end
      end

      # Adds line breaks into file's text
      def fix_add_line_breaks(options)
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_type_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :html_extension
          ),
          options['file_filter'],
          "Adjusting :gap_mark positions",
          options
        ) do |contents, filename|
          with_line_breaks = contents.gsub('</p><p>', "</p>\n<p>")
                                     .gsub('</p><blockquote>', "</p>\n<blockquote>")
                                     .gsub('</blockquote><blockquote>', "</blockquote>\n<blockquote>")
                                     .gsub('</blockquote><p>', "</blockquote>\n<p>")
          [Outcome.new(true, { contents: with_line_breaks }, [])]
        end
      end

      # Insert a record_mark into each content AT file that doesn't contain one
      # already
      def fix_insert_record_mark_into_all_at_files(options)
        # lambda that converts filename to corresponding filename in primary repo
        # Default option works when working on content AT files.
        filename_proc = (
          options['filename_proc'] || lambda { |filename|
            Repositext::Utils::CorrespondingPrimaryFileFinder.find(
              filename: filename,
              language_code_3_chars: config.setting(:language_code_3_chars),
              content_type_dir: config.base_dir(:content_type_dir),
              relative_path_to_primary_content_type: config.setting(:relative_path_to_primary_content_type),
              primary_repo_lang_code: config.setting(:primary_repo_lang_code)
            )
          }
        )
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Inserting record_marks into AT files",
          options
        ) do |contents, filename|
          corresponding_primary_filename = filename_proc.call(filename)
          outcome = Repositext::Process::Fix::InsertRecordMarkIntoAllAtFiles.fix(
            contents,
            filename,
            corresponding_primary_filename
          )
          [outcome]
        end
      end

      # Run this command once on the primary repo to initialize STM CSV and
      # file level data.json files before running first sync subtitles command.
      def fix_prepare_initial_primary_subtitle_sync(options)
        file_list_pattern = config.compute_glob_pattern(
          options['base-dir'] || :content_dir,
          :all_files, # NOTE: We can't allow file-selector since this would result in an incomplete st-ops file
          options['file-extension'] || :at_extension
        )
        file_list = Dir.glob(file_list_pattern)
        if (file_filter = options['file_filter'])
          file_list = file_list.find_all { |filename| file_filter === filename }
        end
        Process::Fix::PrepareInitialPrimarySubtitleSync.new(
          options.merge(
            'config' => config,
            'file_list' => file_list,
            'primary_repository' => content_type.repository,
          )
        ).sync
      end

    end
  end
end
