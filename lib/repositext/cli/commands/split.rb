class Repositext
  class Cli
    # This namespace contains methods related to the `split` command.
    module Split

    private

      # Updates the subtitle_mark character positions in *.subtitle_markers.csv
      # in /content
      def split_subtitles(options)
        if content_type.is_primary_repo
          raise ArgumentError.new("split_subtitles only works on foreign repositories.")
        end

        # First delete all files in st_autosplit directory. This is necessary
        # in particular for the LF Aligner output file. LF Aligner just
        # appends to an existing file rather than overwriting it.
        # LF Aligner also creates a bunch of temporary directories.
        # So to be safe, we just delete everything in the st_autosplit directory.
        delete_directory_contents(
          directory_path: config.base_dir(:autosplit_subtitles_dir)
        )

        # Export all _foreign_ plain_text_for_st_autosplit files
        export_plain_text_for_st_autosplit(options)

        # Export all _primary_ plain_text_for_st_autosplit files
        export_primary_plain_text_for_st_autosplit(options)

        # Update foreign content AT files with subtitles
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
            content_type: content_type,
          )
        ) do |repositext_file|
          o = Repositext::Process::Split::Subtitles.new(
            repositext_file.corresponding_primary_file,
            repositext_file
          ).split
          new_c_at, st_confs = o.result

          [Outcome.new(o.success, { contents: new_c_at }, o.messages)]
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
