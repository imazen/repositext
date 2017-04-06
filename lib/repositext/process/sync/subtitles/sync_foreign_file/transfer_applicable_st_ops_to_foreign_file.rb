class Repositext
  class Process
    class Sync
      class Subtitles
        module SyncForeignFile
          # This namespace provides methods related to transferring subtitle operations
          # to a foreign file.
          module TransferApplicableStOpsToForeignFile

            extend ActiveSupport::Concern

          private

            # Transfers set of applicable_st_ops_for_file successively to
            # foreign_content_at_file. Updates file contents and file_level_st_sync
            # data successively at each iteration.
            # @param foreign_content_at_file [RFile::ContentAt]
            # @param applicable_st_ops_for_file [Array<Subtitle::OperationsForFile>]
            def transfer_applicable_st_ops_to_foreign_file!(foreign_content_at_file, applicable_st_ops_for_file)
              if applicable_st_ops_for_file.any?
                # An st_ops_for_file exists. That means the file is being synced.
                # NOTE: Not sure why we're passing applicable_st_ops_for_file
                # as an array as their should really be only one.

                # Iterate over st_ops and incrementally update both content and data
                found_st_ops = false
                applicable_st_ops_for_file.each do |st_ops_for_file|
                  # Detect if there are st_ops for file, or if it's time slice
                  # changes only.
                  found_st_ops ||= st_ops_for_file.operations.any?
                  transfer_st_ops_to_foreign_file!(
                    foreign_content_at_file,
                    st_ops_for_file
                  )
                  # We have to reload the file contents as they were changed on
                  # disk by #transfer_st_ops_to_foreign_file!
                  foreign_content_at_file.reload_contents!
                end
                # We need to manually write the @to_git_commit to st_sync_commit.
                # We can't rely on transfer_st_ops_to_foreign_file! alone since
                # it will only write sync commits that actually contained st_ops
                # for the current file. However we want to record on the file
                # that it has been synced to the current primary st_sync_commit.
                update_foreign_file_level_data(
                  foreign_content_at_file,
                  @to_git_commit,
                  {} # Don't touch sts that require review
                )
                if found_st_ops
                  # Actual st ops
                  print " - Synced".color(:green)
                else
                  # Time slice changes only
                  print " - Synced (Time slice changes only)".color(:green)
                end
              else
                # No applicable st ops, just update file level st_sync data
                update_foreign_file_level_data(
                  foreign_content_at_file,
                  @to_git_commit,
                  {} # Don't touch sts that require review
                )
                print " - No applicable st_ops"
              end
              true
            end

            # Transfers single st_ops_for_file to foreign_content_at_file.
            # Updates content and data and persists updates to disk.
            # NOTE: It's important that all updates are persisted to disk here
            # so that successive transfer of st_ops_for_file can incrementally
            # update the file.
            # @param foreign_content_at_file [RFile::ContentAt]
            # @param st_ops_for_file [Subtitle::OperationsForFile]
            def transfer_st_ops_to_foreign_file!(foreign_content_at_file, st_ops_for_file)
              from_gc = st_ops_for_file.from_git_commit
              to_gc = st_ops_for_file.to_git_commit

              # Get from_subtitles as of from_gc
              from_subtitles = cached_primary_subtitle_data(
                foreign_content_at_file,
                from_gc,
                :at_commit
              )
              # Get to_subtitles as of the next git commit after to_gc. We have
              # to do this since STM CSV files are updated during st sync,
              # however the changes aren't committed until the next commit
              # after the sync_commit.
              to_subtitles = cached_primary_subtitle_data(
                foreign_content_at_file,
                to_gc,
                :at_next_commit
              )

              # Get new content AT file contents
              fcatf_contents = st_ops_for_file.apply_to_foreign_content_at_file(
                foreign_content_at_file,
                from_subtitles,
                to_subtitles
              )

              # Update content AT file with new contents
              foreign_content_at_file.update_contents!(fcatf_contents)

              # Update file level st_sync data
              update_foreign_file_level_data(
                foreign_content_at_file,
                st_ops_for_file.to_git_commit,
                st_ops_for_file.subtitles_that_require_review,
              )
              true
            end

            # Updates file level st_sync data for foreign_content_at_file
            # @param foreign_content_at_file [RFile::ContentAt]
            # @param sync_commit [String] SHA1 of the to_git_commit
            # @param sts_that_require_review [Hash] with stids as keys and ops types as values
            def update_foreign_file_level_data(
              foreign_content_at_file,
              sync_commit,
              sts_that_require_review
            )
              existing_data = foreign_content_at_file.read_file_level_data
              already_flagged_sts = existing_data['st_sync_subtitles_to_review'] || {}
              new_flagged_sts = already_flagged_sts.merge(sts_that_require_review)

              foreign_content_at_file.update_file_level_data!(
                existing_data.merge({
                  'st_sync_commit' => sync_commit,
                  'st_sync_subtitles_to_review' => new_flagged_sts,
                })
              )
            end
          end
        end
      end
    end
  end
end
