class Repositext
  class Cli
    # This namespace contains methods related to the `git_repo` command.
    module GitRepo

    private

      # Clones all git repos that don't exist on local filesystem yet.
      # Run this from inside primary repo.
      # @param [Hash] options
      def git_repo_clone_missing_repos(options)
        if !config.setting(:is_primary_repo)
          raise "Please run this command from inside the primary repository"
        end
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).git_clone_missing_repos(:all_content_repos)
      end

      # Runs `rt delete all_pdf_exports` on all content repos
      def git_repo_delete_all_pdf_exports(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).delete_all_pdf_exports(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt export pdf_book` on all content repos
      def git_repo_export_pdf_book_all(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).export_pdf_book(
          :all_content_repos,
          content_type
        )
      end

      # Fetches all branches and pulls current branch.
      # @param [Hash] options
      def git_repo_fetch_and_pull_all_content(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).git_fetch_and_pull(:all_content_repos)
      end

      # Runs `rt fix normalize_trailing_newlines` on all content repos
      def git_repo_fix_normalize_trailing_newlines(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).fix_normalize_trailing_newlines(
          :all_content_repos,
          content_type
        )
      end

      # Initializes any empty language repos. Copies standard files from primary repo.
      # Run this from inside primary repo.
      # @param [Hash] options
      def git_repo_initialize_empty_content_repos(options)
        if !config.setting(:is_primary_repo)
          raise "Please run this command from inside the primary repository"
        end
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).initialize_empty_content_repos(Dir.pwd)
      end

      # Pulls latest commits from all upstream code repositories.
      # @param [Hash] options
      def git_repo_pull_all_code(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).git_pull(:code_repos)
      end

      # Pulls latest commits from all upstream content repositories.
      # @param [Hash] options
      def git_repo_pull_all_content(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).git_pull(:all_content_repos)
      end

      # Runs `rt report content_sources` on all content repos
      def git_repo_report_all_content_sources(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).report_content_sources(
          :all_content_repos,
          content_type
        )
      end

      # Runs `rt report quotes_details` on all content repos
      def git_repo_report_all_quotes_details(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).report_quotes_details(
          :all_content_repos,
          content_type
        )
      end

      # Prints git status for all code repositories.
      # @param [Hash] options
      def git_repo_status_all_code(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).git_status(:code_repos)
      end

      # Prints git status for all content repositories.
      # @param [Hash] options
      def git_repo_status_all_content(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).git_status(:all_content_repos)
      end

      # Updates RubyGems in all code and content repos
      def git_repo_update_all_rubygems(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).update_all_rubygems
      end

      # Runs `rt validate content` on all content repos
      def git_repo_validate_all_content(options)
        repos_parent_path = File.expand_path('..', Dir.pwd)
        RepositorySet.new(repos_parent_path).validate_content(
          :all_content_repos,
          content_type
        )
      end

    end
  end
end
