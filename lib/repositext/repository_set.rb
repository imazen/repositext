class Repositext

  # Represents a collection of git content repositories.
  # Assumes that all repositories are siblings in the same folder.

  # Expects current directory to be a repositext content repo root path.

  # Usage example:
  # repository_set = RepositorySet.new('/repositories/parent/path')
  # repository_set.git_pull(:all_content_repos)
  class RepositorySet

    attr_reader :repo_set_parent_path

    # @param repo_set_parent_path [String] path to the folder that contains all repos.
    def initialize(repo_set_parent_path)
      @repo_set_parent_path = repo_set_parent_path
    end

    def all_content_repo_names
      [primary_repo_name] + foreign_content_repo_names
    end

    def all_repo_names
      all_content_repo_names + code_repo_names
    end

    def code_repo_names
      %w[
        repositext
        suspension
      ]
    end

    def foreign_content_repo_names
      %w[
        french
        german
        italian
        spanish
      ]
    end

    # Clones all git repos that don't exist on local filesystem yet.
    # @param repo_set [Symbol, Array<String>] A symbol describing a predefined
    #     group of repos, or an Array with specific repo names as strings.
    # @example Clone all language repos
    #   # cd into primary repo root folder
    #   # run `bundle console`
    #   repository_set = Repositext::RepositorySet.new('/path/to/repos/parent/folder')
    #   repository_set.git_clone_missing_repos(:all_content_repos)
    def git_clone_missing_repos(repo_set)
      compute_repo_paths(repo_set).each { |repo_path|
        repo_name = repo_path.split('/').last
        if File.exists?(repo_path)
          puts " -   Skipping #{ repo_name }"
          next
        end
        puts " - Cloning #{ repo_name }"
        clone_command = "git clone git@vgrtr.vgr.local:vgr-text-repository/#{ repo_name }.git"
        cmd = %(cd #{ repo_set_parent_path } && #{ clone_command })
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          exit_status = wait_thr.value
          if exit_status.success?
            puts "   - Cloned #{ repo_name }"
          else
            msg = %(Could not clone #{ repo_name }:\n\n)
            puts(msg + stderr.read)
          end
        end
      }
    end

    # Pulls all foreign repos
    # @param repo_set [Symbol, Array<String>] A symbol describing a predefined
    #     group of repos, or an Array with specific repo names as strings.
    def git_pull(repo_set)
      compute_repo_paths(repo_set).each { |repo_path|
        cmd = %(cd #{ repo_path } && git pull)
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          exit_status = wait_thr.value
          if exit_status.success?
            puts " - Pulled #{ repo_path }"
          else
            msg = %(Could not pull #{ repo_path }:\n\n)
            puts(msg + stderr.read)
          end
        end
      }
    end

    # Prints git_status for all repos
    # @param repo_set [Symbol, Array<String>] A symbol describing a predefined
    #     group of repos, or an Array with specific repo names as strings.
    def git_status(repo_set)
      compute_repo_paths(repo_set).each { |repo_path|
        puts '-' * 80
        puts "Git status for #{ repo_path }"
        FileUtils.cd(repo_path)
        puts `git status`
      }
      true
    end

    # Initializes any empty content repositories.
    # @param primary_language_repo_path [String]
    def initialize_empty_content_repos(primary_language_repo_path)
      compute_repo_paths(:all_content_repos).each { |repo_path|
        repo_name = repo_path.split('/').last
        if File.exists?(File.join(repo_path, 'Rtfile'))
          puts " -   Skipping #{ repo_name } (Rtfile already exists)"
          next
        end
        puts " - Initializing #{ repo_name }"
        # Create directories
        puts "   - Creating directories"
        create_default_content_directory_structure(repo_path)
        # Copy standard files
        puts "   - Copying standard files"
        copy_default_content_repo_files(repo_path, primary_language_repo_path)
        # TODO: Figure out how to run bundle install from Ruby so it works.
        # Bundle install
        # puts "   - Installing RubyGems"
        # cmd = %(cd #{ repo_path } && bundle install)
        # Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        #   exit_status = wait_thr.value
        #   if exit_status.success?
        #     puts "     - Gems installed"
        #   else
        #     msg = %(Could not install Gems:\n\n)
        #     puts(msg + stderr.read)
        #   end
        # end
      }
    end

    def primary_repo_name
      'english'
    end

    # Replaces text in all repositories
    def replace_text(filename, &block)
    end

    # Allows running of any command (e.g., export, fix, report, validate) on
    # all content repositories.
    def run_repositext_command(command, args)
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

  protected

    # Returns collection of paths to all repos in repo_set
    # @param repo_set [Symbol, Array<String>] A symbol describing a predefined
    #     group of repos, or an Array with specific repo names as strings.
    def compute_repo_paths(repo_set)
      repo_names = case repo_set
      when Array
        repo_set
      when :all_content_repos
        all_content_repo_names
      when :all_repos
        all_repo_names
      when :code_repos
        code_repo_names
      when :foreign_content_repos
        foreign_content_repo_names
      when :primary_repo
        [primary_repo_name]
      else
        raise ArgumentError.new("Invalid repo_set: #{ repo_set.inspect }")
      end
      repo_names.map { |repo_name|
        File.join(repo_set_parent_path, repo_name)
      }
    end

    # @param repo_root_path [String] absolute path to root of repo
    def create_default_content_directory_structure(repo_root_path)
      %w[
        content
        data
        lucene_table_export
        lucene_table_export/json_export
        lucene_table_export/L232
        lucene_table_export/L232/full
        lucene_table_export/L232/full/lucene_index
        lucene_table_export/L232/short
        lucene_table_export/L232/short/lucene_index
        lucene_table_export/L472
        lucene_table_export/L472/full
        lucene_table_export/L472/full/lucene_index
        lucene_table_export/L472/short
        lucene_table_export/L472/short/lucene_index
        pdf_export
        reports
        staging
      ].each do |rel_path|
        FileUtils.mkdir(File.join(repo_root_path, rel_path))
      end
    end

    # @param repo_root_path [String] absolute path to root of new repo
    # @param primary_language_repo_path [String] absolute path
    def copy_default_content_repo_files(repo_root_path, primary_language_repo_path)
      [
        '.gitignore',
        '.ruby-gemset',
        '.ruby-version',
        'Gemfile',
        'readme.md',
        'Rtfile',
      ].each do |filename|
        FileUtils.cp(
          File.join(primary_language_repo_path, filename),
          repo_root_path
        )
      end
    end

  end
end
