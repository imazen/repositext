class Repositext
  class Process
    class Sync
      class Subtitles
        # This namespace provides methods related to syncing subtitles for a foreign file.
        module SyncForeignFile

          extend ActiveSupport::Concern

          include ComputeApplicableStOpsForForeignFile
          include ComputeFromGitCommitForForeignFile
          include TransferApplicableStOpsToForeignFile

          # Syncronizes subtitle operations for the foreign_content_at_file
          # @param foreign_content_at_file [RFile::ContentAt]
          def sync_foreign_file(foreign_content_at_file)
            print "   - #{ foreign_content_at_file.repo_relative_path }: ".ljust(50)

            fgc_o = compute_from_git_commit_for_foreign_file(foreign_content_at_file)
            if fgc_o.success?
              file_from_git_commit = fgc_o.result[:from_git_commit]
              ffgc_source = fgc_o.result[:source]
              print "from_git_commit: #{ file_from_git_commit.inspect }, source: #{ ffgc_source.inspect }"
            else
              msg = fgc_o.messages.join(' ')
              @unprocessable_files << {
                file: foreign_content_at_file,
                message: msg,
              }
              puts msg.color(:red)
              return false
            end

            applicable_st_ops = compute_applicable_st_ops_for_foreign_file(
              foreign_content_at_file,
              file_from_git_commit,
              ffgc_source
            )

            transfer_applicable_st_ops_to_foreign_file!(
              foreign_content_at_file,
              applicable_st_ops
            )
            puts # terminate log line
            true
          end
        end
      end
    end
  end
end
