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
          # @param synced_content_at_files [Array<RFile::ContentAt>] primary files
          def finalize_sync_operation(primary_repo, git_to_commit, synced_content_at_files)
            puts " - Finalizing subtitle sync".color(:blue)
            # Record git_to_commit at primary repo level
            primary_repo.update_repo_level_data('st_sync_commit' => git_to_commit)
            # Reset st_sync_required at primary file level
            synced_content_at_files.each { |content_at_file|
              content_at_file.update_file_level_data('st_sync_required' => false)
            }
            true
          end

        end
      end
    end
  end
end
