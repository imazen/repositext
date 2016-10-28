# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        # This namespace provides methods related to ensuring that all content repos
        # are ready for a subtitle sync.
        module EnsureAllContentReposAreReady

          extend ActiveSupport::Concern

          # Makes sure that no content repo has uncommitted changes and pulls
          # newest from origin.
          def ensure_all_content_repos_are_ready
            find_invalid_repos
            find_invalid_primary_st_ops_filenames
          end

        private

          # Finds any git repos that are not ready and raises an exception.
          def find_invalid_repos
            repos_parent_path = File.expand_path('..', @primary_repository.base_dir)
            repos_with_issues = RepositorySet.new(
              repos_parent_path
            ).git_ensure_repos_are_ready(
              :all_content_repos
            ) { |repo_path| puts "   - #{ repo_path.split('/').last }" }
            # TODO: Use #all_synced_foreign_repos instead of the RepositorySet method. Requires a refactoring.
            repos_with_issues += ensure_st_ops_filenames_are_valid
            if repos_with_issues.any?
              puts
              puts "Could not proceed because the following git repositories are not ready:".color(:red)
              puts
              repos_with_issues.each { |repo_path, issues|
                puts repo_path
                puts '-' * 40
                issues.each { |e| puts " - #{ e }".color(:red) }
              }
              puts
              raise ReposNotReadyError.new(
                "\n\nCannot proceed with synching subtitles until all content repos are clean!".color(:red)
              )
            end
            true
          end

          # Finds any st-ops files in primary repo that have invalid filenames
          # and raises an exception.
          def find_invalid_primary_st_ops_filenames
            # TODO: Validate that st-ops-files in primary repo have no
            # duplicate time stamps, and that from and to commits form a
            # contiguos, linear sequence.
            true
          end

        end
      end
    end
  end
end
