class Repositext
  class Process
    class Sync
      class Subtitles
        module SyncForeignFile
          # This namespace provides methods related to computing the `from_git_commit`
          # for a foreign file.
          module ComputeFromGitCommitForForeignFile

            extend ActiveSupport::Concern

          private

            # Computes the from_git_commit required for foreign_content_at_file.
            # @param foreign_content_at_file [RFile::ContentAt]
            # @return [Outcome] if successful with the following result:
            #         { from_git_commit: <the sync commit's SHA1>, source: <Symbol> }
            #         if not successful, #messages contains details.
            def compute_from_git_commit_for_foreign_file(foreign_content_at_file)
              # Use file level st_sync_commit if it exists.
              file_level_st_sync_commit = foreign_content_at_file.read_file_level_data['st_sync_commit']
              if file_level_st_sync_commit
                return Outcome.new(
                  true,
                  {
                    from_git_commit: file_level_st_sync_commit,
                    source: :file_level_data,
                  }
                )
              end

              # Otherwise try to get commit from subtitle export file, or autosplit
              if(st_export_markers_file = foreign_content_at_file.corresponding_subtitle_export_markers_file)
                compute_from_git_commit_via_st_export_file(
                  foreign_content_at_file,
                  st_export_markers_file
                )
              else
                autosplit_foreign_file!(
                  foreign_content_at_file
                )
              end
            end

            # Computes the from_git_commit for foreign_content_at_file using
            # time stamps of the latest commits to the corresponding subtitle
            # export and import files, and then mapping them to the primary repo.
            # @param foreign_content_at_file [RFile::ContentAt]
            # @param st_export_markers_file [RFile::SubtitleMarkerCsv]
            # @return [Outcome] if successful with the following result:
            #         { from_git_commit: <the sync commit's SHA1>, source: <Symbol> }
            #         if not successful, #messages contains details.
            def compute_from_git_commit_via_st_export_file(foreign_content_at_file, st_export_markers_file)
              st_import_txt_file = foreign_content_at_file.corresponding_subtitle_import_txt_file
              if st_import_txt_file.nil?
                return(
                  Outcome.new(
                    false,
                    nil,
                    ["Pending subtitle import: There is no subtitle import file"]
                  )
                )
              end

              # Find the latest commits that affected st export/import files.
              latest_st_export_file_commit = st_export_markers_file.latest_git_commit
              latest_st_import_file_commit = st_import_txt_file.latest_git_commit
              [
                [st_export_markers_file, latest_st_export_file_commit],
                [st_import_txt_file, latest_st_import_file_commit],
              ].each { |(stf, stf_commit)|
                if stf_commit.nil?
                  return(
                    Outcome.new(
                      false,
                      nil,
                      ["No git commit found for subtitle export/import file #{ stf.repo_relative_path }"]
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
                  ["Pending subtitle import: Import time is before export time"]
                )
              end

              # Find the latest commit to the corresponding primary file
              # before latest_st_export_time.
              corr_prim_content_at_file = foreign_content_at_file.corresponding_primary_file
              st_exported_at_primary_commit = corr_prim_content_at_file.latest_git_commit(
                latest_st_export_time
              )

              # Don't go back any further than the earliest st_sync `from` commit.
              if st_exported_at_primary_commit.time.utc < @earliest_from_git_commit.time.utc
                st_exported_at_primary_commit = @earliest_from_git_commit
              end

              # Validate that english_content_at_file at st_exported_at_primary_commit
              # has same number of subtitles as foreign_content_at_file.
              exported_corr_prim_content_at_file = corr_prim_content_at_file.as_of_git_commit(
                st_exported_at_primary_commit.oid
              )
              if(
                (ecpcaf_stc = exported_corr_prim_content_at_file.subtitle_marks_count) !=
                (fcaf_stc = foreign_content_at_file.subtitle_marks_count)
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
                      ") at git commit ",
                      st_exported_at_primary_commit.oid.inspect,
                    ].join
                  ]
                )
              end

              # Return the git commit based on the subtitle export file
              Outcome.new(
                true,
                {
                  from_git_commit: st_exported_at_primary_commit.oid,
                  source: :subtitle_export
                }
              )
            end

            def autosplit_foreign_file!(foreign_content_at_file)
              Outcome.new(
                false,
                nil,
                ["Foreign file has no subtitle export/imports, however it contains subtitles."]
              )
                  # Does foreign_content_at_file have any subtitles?
                  #   Yes
                  #     return [nil, :resolve_existing_subtitles_manually]
                  #   No
                  #     Auto split file based on to_git_commit
                  #     set st_sync_autosplit to true
                  #     return [<to_git_commit>, :from_autosplit]
              Outcome.new(
                true,
                {
                  from_git_commit: @to_git_commit,
                  source: :autosplit
                }
              )
            end
          end
        end
      end
    end
  end
end
