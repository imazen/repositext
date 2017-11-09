class Repositext
  class Cli
    # This namespace contains methods related to the `split` command.
    module Split

    private

      # Updates the subtitle_mark character positions in *.subtitle_markers.csv
      # in /content
      def split_subtitles(options)
        # Make sure we're not in primary repo
        if content_type.is_primary_repo
          raise ArgumentError.new("the `split subtitles` command only works on foreign repositories.")
        end
        # Make sure that 'file-selector' option is given.
        if '' == options['file-selector'].to_s.strip
          raise(ArgumentError.new("You must provide the file-selector command line option for this command!"))
        end

        # Compute primary sync_commit
        primary_repo = content_type.corresponding_primary_content_type.repository
        primary_repo_sync_commit = primary_repo.read_repo_level_data['st_sync_commit']

        # Update foreign content AT files with subtitles
        files_that_could_not_be_auto_split = []
        Repositext::Cli::Utils.change_files_in_place(
          config.compute_glob_pattern(
            options['base-dir'] || :content_dir,
            options['file-selector'] || :all_files,
            options['file-extension'] || :at_extension
          ),
          options['file_filter'],
          "Splitting subtitles",
          options
        ) do |f_content_at_file|
          # Skip this foreign file if primary file requires st_sync
          p_content_at_file = f_content_at_file.corresponding_primary_file
          o = Repositext::Process::Split::Subtitles.new(
            p_content_at_file,
            f_content_at_file,
            { remove_existing_sts: options['remove-existing-sts'] }
          ).split

          # Update foreign content_at file's st_sync_commit and set st_autosplit flag
          if o.success
            f_content_at_file.update_file_level_data!(
              'st_sync_commit' => primary_repo_sync_commit,
              'st_sync_subtitles_to_review' => { 'all' => ['autosplit'] }
            )
          end
          new_c_at, _st_confs = o.result

          [Outcome.new(o.success, { contents: new_c_at }, o.messages)]
        end
        if files_that_could_not_be_auto_split.any?
          puts "The following files could not be autosplit because their corresponding primary file requires a subtitle sync:".color(:red)
          puts "=============================================================================================================".color(:red)
          files_that_could_not_be_auto_split.each do |content_at_file|
            puts " * #{ content_at_file.filename }".color(:red)
          end
        end
      end

      def export_primary_plain_text_for_st_autosplit(options)
        # Recursively call `export_plain_text_for_st_autosplit` with some options
        # modified. We call it via `Cli.start` so that we can use a different Rtfile.
        primary_repo_rtfile_path = File.join(config.primary_content_type_base_dir, 'Rtfile')
        args = [
          "export",
          "plain_text_for_st_autosplit",
          "--content-type-name", options['content-type-name'], # use same content_type
          "--file-selector", (options['file-selector'] || :all_files), # use same file-selector
          "--rtfile", primary_repo_rtfile_path # use primary repo's Rtfile
        ]
        args << '--skip-git-up-to-date-check'  if options['skip-git-up-to-date-check']
        Repositext::Cli.start(args)
      end

      def split_test(options)
        # dummy method for testing
        puts 'split_test'
      end

    end
  end
end
