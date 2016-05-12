# encoding UTF-8
class Repositext
  class Process
    class Sync

      # Synchronizes subtitles from English to foreign repos.
      #
      class Subtitles

        class ReposNotReadyError < StandardError; end

        # Initialize a new subtitle sync process
        def initialize(options)
          @options = options
        end

        def sync
          ensure_all_content_repos_are_ready
          extract_and_store_primary_subtitle_operations
          # update_primary_subtitle_marker_csv_files(options)
          # transfer_subtitle_operations_to_foreign_repos(options)
        end

      private

        # Makes sure that no content repo has uncommitted changes and pulls
        # newest from origin.
        def ensure_all_content_repos_are_ready
          repos_parent_path = File.expand_path('../../../../../..', __FILE__)
          puts
          puts "Ensuring that all content repos are ready"
          puts
          repos_with_issues = RepositorySet.new(
            repos_parent_path
          ).git_ensure_repos_are_ready(
            :test_content_repos,
            ->(repo_path){ puts " * #{ repo_path }" }
          )
          if repos_with_issues.any?
            puts
            puts "Could not proceed because the following git repositories are not ready:"
            puts
            repos_with_issues.each { |repo_path, issues|
              puts repo_path
              puts '-' * 40
              issues.each { |e| puts " - #{ e }" }
            }
            puts
            raise ReposNotReadyError.new
          end
        end

        def extract_and_store_primary_subtitle_operations
        end

      end
    end
  end
end
