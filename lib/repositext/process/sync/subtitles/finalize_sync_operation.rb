# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module FinalizeSyncOperation

          extend ActiveSupport::Concern

          # Finalizes the subtitles sync operation
          # @param primary_repo [Repository]
          # @param git_to_commit [String]
          def finalize_sync_operation(primary_repo, git_to_commit)
            primary_repo.update_repo_level_data(
              'subtitles_last_synched_at_git_commit' => git_to_commit
            )
            true
          end

        private

        end
      end
    end
  end
end
