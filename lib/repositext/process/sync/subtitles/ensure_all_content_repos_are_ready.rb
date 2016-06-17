# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module EnsureAllContentReposAreReady

          extend ActiveSupport::Concern

          # Makes sure that no content repo has uncommitted changes and pulls
          # newest from origin.
          def ensure_all_content_repos_are_ready
            # TODO: This only works if code and content repos are in same parent repo.
            # Will break if we install this as a gem.
            # To fix it: Start from a @config.base_dir instead of this file's location.
            repos_parent_path = File.expand_path('../../../../../..', __FILE__)
            puts
            puts "Ensuring that all content repos are ready"
            puts
            repos_with_issues = RepositorySet.new(
              repos_parent_path
            ).git_ensure_repos_are_ready(
              :test_content_repos
            ) { |repo_path| puts " * #{ repo_path.split('/').last }" }
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
          end

        private

        end
      end
    end
  end
end
