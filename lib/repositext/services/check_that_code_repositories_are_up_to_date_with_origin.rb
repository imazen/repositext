class Repositext
  class Services

    # This service checks that all local repositext core code repositories
    # are up-to-date with their `origin` remotes.
    # It raises an exception if they are not.
    #
    # Usage:
    #    Repositext::Services::CheckThatCodeRepositoriesAreUpToDateWithOrigin.call(
    #      '/path/to/repositext_parent_dir'
    #    )
    class CheckThatCodeRepositoriesAreUpToDateWithOrigin

      def self.call(repositext_parent_dir)
        new(repositext_parent_dir).call
      end

      # @param repositext_parent_dir [String] absolute path to repo that
      #   contains all repositext repositories.
      def initialize(repositext_parent_dir)
        @repositext_parent_dir = repositext_parent_dir
      end

      def call
        repos_that_are_not_up_to_date = []
        # Check core code repos
        RepositorySet.new(@repositext_parent_dir)
                     .all_repos(:core_code_repos)
                     .each { |repository|
                       if !repository.up_to_date_with_remote?
                         repos_that_are_not_up_to_date << repository
                       end
                     }
        # Check vgr-table-releases repo
        additional_repos_to_check.each { |repo_name|
          additional_repo_dir = File.join(@repositext_parent_dir, repo_name)
          additional_repo = Repository.new(additional_repo_dir)
          if !additional_repo.up_to_date_with_remote?
            repos_that_are_not_up_to_date << additional_repo
          end
        }
        # Raise if any are out of date
        if repos_that_are_not_up_to_date.any?
          raise Repository::NotUpToDateWithRemoteError.new([
            '',
            "The following code git repositories are not up-to-date with their remote:",
            repos_that_are_not_up_to_date.map { |e| %( * #{ e.name_and_current_branch }) },
            'Please get the updates from origin/master first before running this command.',
            'You can bypass this check by appending "--skip-git-up-to-date-check=true" to the repositext command'
          ].join("\n"))
        end
      end

      # Override this in sub classes to add more repos.
      def additional_repos_to_check
        []
      end

    end
  end
end
