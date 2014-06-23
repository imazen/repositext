class Repositext
  class Repository

    def initialize
      @repo_path = Rugged::Repository.discover(Dir.pwd)
      @repo = Rugged::Repository.new(@repo_path)
      @head_ref = @repo.head
    end

    # Returns the repo name, based on name of parent directory
    def name
      @repo.workdir.split('/').last
    end

    # Returns sha of latest commit that included filename
    # @param[String] filename
    # @return[Rugged::Commit] a commit git object. Responds to the following
    # methods:
    # * #time (the time of the commit)
    # * #oid (the sha of the commit)
    def latest_commit(filename)
      @repo.lookup(latest_commit_sha(filename))
    end

    # Returns name of currently checked out branch
    def current_branch_name
      @head_ref.name.sub(/^refs\/heads\//, '')
    end

  private

    # We shell out to git log to get the latest commit's sha. This is orders of
    # magnitudes faster than using Rugged walker. See this ticket for more info:
    # https://github.com/libgit2/rugged/issues/343#issue-30232795
    # @param[String] filename
    # @return[String] the sha1 of the commit
    def latest_commit_sha(filename)
      s, _ = Open3.capture2(
        [
          "git",
          "--git-dir=#{ @repo_path }",
          "log",
          "-1",
          "--pretty=format:'%H'",
          "--",
          filename.sub(/#{ @repo.workdir }\//, ''),
        ].join(' ')
      )
      s
    end

  end
end
