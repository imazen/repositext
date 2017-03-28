class Repositext
  class Process
    class Compute

      # Computes the subtitle sync `from` git commit for a foreign file.
      # Handles the following scenarios:
      # * Initial st-sync
      #     * File already has subtitles
      #         * Uses correlation of git commits in foreign and primary repo
      #           to determine what commit in the primary repo the subtitles in
      #           self are synced to. Please see "Determining primary sync commit"
      #           below for details.
      #         * Returns the SHA1 commit hash.
      #     * File has no subtitles
      #         * File is not synced to any primary commit, requires auto-split.
      #         * Returns nil
      # * Ongoing st-sync
      #     * File is in sync with a previous primary sync commit.
      #     * Returns the SHA1 commit hash.
      #
      # ## Determining primary sync commit
      #
      # In order to determine the primary git commit to which the foreign file is
      # synced with, we use time stamps of the latest commits to the corresponding
      # foreign subtitle export and import files, and then mapping them to the
      # primary repo to find out at what point in time (and git commit) the
      # subtitles for @foreign_content_at_file were last updated.
      class StSyncFromGitCommitForForeignFile

        # @param foreign_content_at_file [RFile::ContentAt]
        # @param earliest_from_git_commit [Rugged::Commit, nil]
        #     Earliest commit allowed, or nil if no limit enforced.
        # @param config [Repositext::Cli::Config]
        def initialize(foreign_content_at_file, earliest_from_git_commit, config)
          @foreign_content_at_file = foreign_content_at_file
          @earliest_from_git_commit = earliest_from_git_commit
          @config = config
        end

        # Computes the from_git_commit required for @foreign_content_at_file.
        # @return [Outcome] if successful with the following result:
        #         { from_git_commit: <the sync commit's SHA1 or nil>, source: <Symbol> }
        #         if not successful, #messages contains details.
        def compute
          if is_initial_foreign_sync?
            if file_has_subtitles?
              use_corresponding_primary_st_sync_commit
            else # file has no subtitles
              file_requires_initial_subtitle_autosplit
            end
          else # this is a subsequent st sync
            use_file_level_st_sync_commmit
          end
        end

        # Returns a positive outcome with the st sync commit of the corresponding
        # primary commit if it can be found.
        # Note: That commit may not be aligned with an official sync commit and
        # as a consequence may require a custom st-ops file.
        # Otherwise returns a negative outcome.
        # @return [Outcome] where the outcome's result is a Hash of the following
        # shape:
        #   {
        #     from_git_commit: 'a1b2c3',
        #     source: :subtitle_export
        #   },
        def use_corresponding_primary_st_sync_commit
          outcome = compute_corresponding_primary_st_sync_commit
          if outcome.success
            outcome
          else
            Outcome.new(
              false,
              {
                from_git_commit: nil,
                source: :subtitle_export
              },
              outcome.messages
            )
          end
        end

        # Returns a positive outcome with a nil :from_git_commit to indicate
        # that an initial subtitle autosplit is required.
        # @return [Outcome]
        def file_requires_initial_subtitle_autosplit
          Outcome.new(
            false,
            {
              from_git_commit: nil,
              source: :autosplit
            },
            ['File requires autosplit.']
          )
        end

        # Returns a positive outcome with the st sync commit SHA1 from the
        # previous st sync.
        # @return [Outcome]
        def use_file_level_st_sync_commmit
          if(flssc = get_file_level_st_sync_commit)
            return Outcome.new(
              true,
              {
                from_git_commit: flssc,
                source: :file_level_data,
              },
              ["This file has been synced before. Start from previous sync commit."]
            )
          else
            raise "Handle this!"
          end
        end

      private

        # Returns the corresponding_primary_st_sync_commit if successful,
        # otherwise a tuple of nil and error messages.
        # @return [Outcome]
        def compute_corresponding_primary_st_sync_commit
          # We're using the English plain text file to find the time of last
          # export. The English plain text file would contain any changes
          # (content as well as subtitles), so we'd be sure that it will yield
          # the correct time stamp.
          st_export_en_txt_file = @foreign_content_at_file.corresponding_subtitle_export_en_txt_file
          if st_export_en_txt_file.nil?
            return(
              Outcome.new(
                false,
                nil,
                ["   x The content AT file has subtitle marks, however no subtitle export file (*.en.txt) was found."]
              )
            )
          end

          st_import_txt_file = @foreign_content_at_file.corresponding_subtitle_import_txt_file
          if st_import_txt_file.nil?
            return(
              Outcome.new(
                false,
                nil,
                ["   x We found a subtitle export file, however no subtitle import file was found."]
              )
            )
          end

          # Find the latest commits that affected st export/import files.
          latest_st_export_file_commit = st_export_en_txt_file.latest_git_commit
          latest_st_import_file_commit = st_import_txt_file.latest_git_commit
          [
            [st_export_en_txt_file, latest_st_export_file_commit],
            [st_import_txt_file, latest_st_import_file_commit],
          ].each { |(stf, stf_commit)|
            if stf_commit.nil?
              return(
                Outcome.new(
                  false,
                  nil,
                  ["   x Could not find latest git commit for file #{ stf.repo_relative_path(true).inspect }"]
                )
              )
            end
          }
          # Extract time stamps from latest commits.
          latest_st_export_time = latest_st_export_file_commit.time.utc
          latest_st_import_time = latest_st_import_file_commit.time.utc
          if latest_st_import_time < latest_st_export_time
            return Outcome.new(
              false,
              nil,
              ["   x Found invalid subtitle import: The latest import is prior to the latest export."]
            )
          end

          # Find the latest commit to the corresponding primary file
          # before latest_st_export_time.
          corr_prim_content_at_file = @foreign_content_at_file.corresponding_primary_file
          st_exported_at_primary_commit = corr_prim_content_at_file.latest_git_commit(
            latest_st_export_time
          )
          puts
          puts "     - latest_st_export_time: #{ latest_st_export_time.inspect }"
          puts "     - st_exported_at_primary_commit: #{ st_exported_at_primary_commit.oid }, (#{ st_exported_at_primary_commit.time.utc })"

          # Don't go back any further than the earliest st_sync `from` commit.
          effective_from_git_commit = if(
            @earliest_from_git_commit &&
            st_exported_at_primary_commit.time.utc < @earliest_from_git_commit.time.utc
          )
            @earliest_from_git_commit
          else
            st_exported_at_primary_commit
          end

          puts "     - earliest_from_git_commit: #{ @earliest_from_git_commit.oid }"
          puts "     - effective_from_git_commit: #{ effective_from_git_commit.oid } (#{ effective_from_git_commit.time.utc })"

          # Validate that english_content_at_file at effective_from_git_commit
          # has same number of subtitles as foreign_content_at_file.
          exported_corr_prim_content_at_file = corr_prim_content_at_file.as_of_git_commit(
            effective_from_git_commit.oid
          )
          if(
            (ecpcaf_stc = exported_corr_prim_content_at_file.subtitle_marks_count) !=
            (fcaf_stc = @foreign_content_at_file.subtitle_marks_count)
          )
            return Outcome.new(
              false,
              nil,
              [
                [
                  "Subtitle count mismatch between exported primary file (",
                  ecpcaf_stc,
                  ") and foreign file (",
                  fcaf_stc,
                  ") at primary git commit ",
                  effective_from_git_commit.oid.inspect,
                ].join
              ]
            )
          end

          # Validate that english_content_at_file at effective_from_git_commit
          # has same plain text and subtitles as subtitle export *.en.txt file
          # Since the kramdown parser is specified as module in Rtfile,
          # I can't use the standard kramdown API:
          # `doc = Kramdown::Document.new(contents, :input => 'kramdown_repositext')`
          # We have to patch a base Kramdown::Document with the root to be able
          # to convert it.
          root, warnings = @config.kramdown_parser(:kramdown).parse(exported_corr_prim_content_at_file.contents)
          doc = Kramdown::Document.new('')
          doc.root = root
          exp_corr_prim_plain_txt_with_sts = doc.send(@config.kramdown_converter_method(:to_subtitle))
          if(
            (ecpptws = exp_corr_prim_plain_txt_with_sts) !=
            (seetfc = st_export_en_txt_file.contents)
          )
            return Outcome.new(
              false,
              nil,
              [
                [
                  "Mismatch between primary content AT file ",
                  "and foreign subtitle export *.en.txt file ",
                  "at primary git commit ",
                  effective_from_git_commit.oid.inspect,
                  " (#{ @foreign_content_at_file.basename })"
                ].join,
                Suspension::StringComparer.compare(ecpptws, seetfc)
              ]
            )
          end

          # Return the git commit based on the subtitle export file
          Outcome.new(
            true,
            {
              from_git_commit: effective_from_git_commit.oid,
              source: :subtitle_export
            },
            ["Found corresponding primary commit from #{ effective_from_git_commit.time.to_s } (#{ effective_from_git_commit.oid.first(10) })"]
          )
        end

        # Returns true if @foreign_content_at_file has subtitles.
        # @return [Boolean]
        def file_has_subtitles?
          @foreign_content_at_file.has_subtitle_marks?
        end

        # @return [String, nil] the file level st sync git commit
        def get_file_level_st_sync_commit
          @foreign_content_at_file.read_file_level_data['st_sync_commit']
        end

        # Returns true if @foreign_content_at_file's subtitles have never been
        # synced. We determine this by the absence of the file level
        # 'st_sync_commit' data setting.
        # @return [Boolean]
        def is_initial_foreign_sync?
          !get_file_level_st_sync_commit
        end

      end
    end
  end
end
