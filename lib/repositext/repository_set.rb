class Repositext

  # Represents a collection of git content repositories
  class RepositorySet

    def all_repo_names
      foreign_repo_names + code_repo_names
    end

    def primary_repo_path
      # TODO: make this based on pwd
      '/Users/johund/development/vgr-english'
    end

    def foreign_repo_names
      # %w[
      #   vgr-english
      #   vgr-spanish
      # ]
      []
    end

    def code_repo_names
      %w[
        repositext
        repositext-guide
        repositext-ui
        suspension
        vgr-repositext
        vgr-table-export
        vgr-table-sync-spec
      ]
    end

    # Pulls all foreign repos
    def git_pull
      # iterate over all foreign repos
        # `git pull`
    end

    # Prints git_status for all repos
    def git_status
      relative_repo_paths.each { |relative_repo_path|
        puts '-' * 80
        puts "Git status for #{ relative_repo_path.split('/').last.inspect }"
        FileUtils.cd(File.expand_path(relative_repo_path, primary_repo_path))
        puts `git status`
      }
      true
    end

    # Provides relative repo paths from the root of the primary repo to all foreign repos
    def relative_repo_paths
      all_repo_names.map { |repo_name|
        File.join(primary_repo_path, "../#{ repo_name }")
      }
    end

    # Replaces text in all repositories
    def replace_text(filename, &block)
    end

    # Synchronizes gems in all foreign repos with those of primary repo
    def synchronize_gems_with_primary_repo
      # iterate over all foreign repos
        # Copy Gemfile and Gemfile.lock from primary repo
        # call `bundle install`
        # make sure git index is empty
        # add Gemfile and Gemfile.lock to git index
        # `git commit`
        # `git push`
    end

  end
end
