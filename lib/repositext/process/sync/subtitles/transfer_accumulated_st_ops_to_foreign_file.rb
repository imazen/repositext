# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        # Use methods in this module to transfer any accumulated subtitle operations
        # to a foreign file after subtitles have been imported.
        #
        # This module is required if new subtitle operations have been synced
        # while a foreign file was locked because of a pending subtitle import.
        # (I.e. subtitles in the foreign file were exported at a previous sync
        # sync commit, and have now been imported. To complete the import,
        # we apply any subtitle operations that have been extracted since the
        # subtitle export.)
        #
        # Use like so:
        # ss = Repositext::Process::Sync::Subtitles.new('config' => cli_config)
        # ss.transfer_accumulated_st_ops_to_foreign_file('123456abcdef', content_at_file)
        module TransferAccumulatedStOpsToForeignFile

          extend ActiveSupport::Concern

          # @param export_sync_commit [String] sha1 of the sync commit at which
          #        subtitles were exported. All st ops since then will be transferred.
          # @param content_at_file [RFile::ContentAt] the foreign content AT file
          #        to transfer subtitle ops to.
          # Makes changes in place in content_at_file and corresponding data.json file.
          def transfer_accumulated_st_ops_to_foreign_file(export_sync_commit, content_at_file)
            accumulated_sync_commits = Subtitle::OperationsFile.get_sync_commits(
              @config.base_dir(:subtitle_operations_dir),
              export_sync_commit
            )
            accumulated_sync_commits.each_cons(2) { |from_commit, to_commit|
              # TODO: Should we instantiate new Sync::Subtitles object instead
              # mutating this one's state in place?
              @from_git_commit = from_commit
              @to_git_commit = to_commit
              st_ops_for_repo = extract_or_load_primary_subtitle_operations(true)
              st_ops_for_file = st_ops_for_repo.get_operations_for_file(
                content_at_file.extract_product_identity_id
              )
              next  if st_ops_for_file.nil?
              transfer_subtitle_operations_for_primary_file!(
                st_ops_for_file,
                [],
                content_at_file
              )
              content_at_file.update_file_level_data(
                {
                  'st_sync_commit' => to_commit,
                  'st_sync_subtitles_to_review' => {},
                }
              )
            }
            true
          end

        end
      end
    end
  end
end
