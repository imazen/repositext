class Repositext
  class Cli
    module GitRepo

    private

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

    end
  end
end
