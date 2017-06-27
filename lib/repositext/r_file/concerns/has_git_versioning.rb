class Repositext
  class RFile
    # Provides behavior around git versioning
    module HasGitVersioning

      extend ActiveSupport::Concern

      class FileDidNotExistAtRefCommitError < StandardError; end

      included do
        # [ref_commit, relative_version] where ref_commit is the commit SHA1
        # and relative_version see #as_of_git_commit.
        attr_accessor :as_of_git_commit_attrs
        attr_accessor :do_not_load_contents_from_disk_for_testing
      end

      # Returns copy of self with contents as of a ref_commit or one of its
      # children.
      # relative_version can be one of:
      #   * :at_child_or_current
      #     Returns contents at a child commit if it affected self, otherwise
      #     current file contents. Raises file not found error if current file
      #     does not exist.
      #   * :at_child_or_nil
      #     Returns contents at a child commit if it affected self, otherwise nil.
      #   * :at_child_or_ref
      #     Returns contents at a child commit if it affected self, otherwise the
      #     contents at reference commit. Returns nil if file didn't exist at
      #     either of the two commits.
      #   * :at_ref_or_nil - Returns contents as of the ref_commit, or Nil if
      #     file didn't exist at commit.
      #   * :at_ref_or_raise - Returns contents as of the ref_commit, or raises
      #     exception if file didn't exist at commit.
      # @param ref_commit [String]
      # @param relative_version [Symbol]
      # @return [RFile, nil]
      def as_of_git_commit(ref_commit, relative_version=:at_ref_or_nil)
        return self  if do_not_load_contents_from_disk_for_testing

        if !ref_commit.is_a?(String)
          raise ArgumentError.new("Invalid ref_commit: #{ ref_commit.inspect }")
        end
        if '' == ref_commit.to_s
          raise ArgumentError.new("Invalid ref_commit: #{ ref_commit.inspect }")
        end

        # Get any child commits of ref_commit that affected self.
        cmd = [
          "git",
          "--git-dir=#{ repository.repo_path }",
          "log",
          "--format='%H %P'",
          "--",
          repo_relative_path,
          %(| grep -F " #{ ref_commit }"),
          '| cut -f1 -d" "',
        ].join(' ')
        all_child_commit_sha1s, std_error, status = Open3.capture3(cmd)
        child_commit_including_self = (all_child_commit_sha1s.lines.first || '').strip

        # Instantiate copy of self with contents as of the requested relative_version
        new_contents = case relative_version
        when :at_child_or_current
          if '' == child_commit_including_self
            # Use current file contents
            is_binary ? File.binread(filename) : File.read(filename)
          else
            # Use file contents at child commit
            get_contents_as_of_git_commit(child_commit_including_self)
          end
        when :at_child_or_nil
          if '' == child_commit_including_self
            # Return nil instead of RFile
            nil
          else
            # Use file contents at child commit
            get_contents_as_of_git_commit(child_commit_including_self)
          end
        when :at_child_or_ref
          # Use contents at a child commit if it affected self, otherwise use contents at ref_commit.
          if '' == child_commit_including_self
            # Use file contents at ref_commit
            get_contents_as_of_git_commit(ref_commit)
          else
            # Use file contents at child commit
            get_contents_as_of_git_commit(child_commit_including_self)
          end
        when :at_ref_or_nil
          # Use contents as of ref_commit, or nil
          get_contents_as_of_git_commit(ref_commit)
        when :at_ref_or_raise
          # Use contents as of ref_commit, or raise exception
          r = get_contents_as_of_git_commit(ref_commit)
          if r.nil?
            raise FileDidNotExistAtRefCommitError.new(
              "File #{ filename.inspect } did not exist at git commit #{ ref_commit.inspect }".color(:red)
            )
          end
          r
        else
          raise "Handle this: #{ relative_version.inspect }"
        end
        if new_contents.nil?
          # Return nil, not a new instance of self
          nil
        else
          # Return new instance of self with updated contents and attrs
          r = self.class.new(new_contents, language, filename, content_type)
          r.as_of_git_commit_attrs = [ref_commit, relative_version]
          r
        end
      end

      # Returns true if self was instantiated via #as_of_git_commit
      def is_git_versioned?
        !as_of_git_commit_attrs.nil?
      end

      # Returns the latest git commit that included self. Before_time is optional
      # and defaults to now.
      # @param before_time [Time, optional]
      # @return [Rugged::Commit]
      def latest_git_commit(before_time=nil)
        return nil  if repository.nil?
        repository.latest_commit(filename, before_time)
      end

    protected

      # Gets contents of self after git_commit. Returns nil if self did not yet
      # exist at git_commit.
      # @param git_commit [String]
      # @return [String, Nil]
      def get_contents_as_of_git_commit(git_commit)
        cmd = "git --git-dir=#{ repository.repo_path } --no-pager show #{ git_commit }:#{ repo_relative_path }"
        file_contents, std_err, process_status = Open3.capture3(cmd)
        process_status.success? ? file_contents : nil
      end

    end
  end
end
