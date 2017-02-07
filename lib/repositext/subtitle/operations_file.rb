class Repositext
  class Subtitle

    # Represents a subtitle operations file (stored in primary repo).
    #
    # All Subtitle::OperationsFiles are stored in a folder 'subtitle_operations'
    # in the primary repository's root folder.
    #
    # st ops file names have the following format:
    #     "st-ops-2016_07_12-20_39_28-123456-to-654321.json"
    class OperationsFile

      # Returns true if any of the st-ops files in st_ops_dir are bounded by
      # git_commit_sha1
      # @param st_ops_dir [String]
      # @param git_commit_sha1 [String]
      # @return [Boolean]
      def self.any_with_git_commit?(st_ops_dir, git_commit_sha1)
        gcsha1 = truncate_git_commit_sha1(git_commit_sha1)
        Dir.glob(File.join(st_ops_dir, "st-ops-*-#{ gcsha1 }*.json")).any?
      end

      # Returns the SHA1 of the earliest `from_git_commit` in st_ops_dir
      # @param st_ops_dir [String]
      # @return [String]
      def self.compute_earliest_from_commit(st_ops_dir)
        earliest_st_ops_file_name = find_earliest(st_ops_dir)
        return nil  if earliest_st_ops_file_name.nil?
        extract_from_and_to_commit_from_filename(earliest_st_ops_file_name).first
      end

      # Returns a string to be used in st-ops file names to document the sync
      # commits. Example: "123456-to-654321"
      # @param from_commit [String] sha1 hash of from-commit
      # @param to_commit [String] sha1 hash of to-commit
      # @return [String]
      def self.compute_from_to_git_commit_marker(from_commit, to_commit)
        [
          truncate_git_commit_sha1(from_commit),
          '-to-',
          truncate_git_commit_sha1(to_commit),
        ].join
      end

      # Returns an array with `from` and `to` git commits from the latest st-ops
      # file if any exist. Otherwise returns empty array.
      # @param st_ops_dir [String]
      # @return [Array<String>]
      def self.compute_latest_from_and_to_commits(st_ops_dir)
        latest_st_ops_file_name = find_latest(st_ops_dir)
        return []  if latest_st_ops_file_name.nil?
        extract_from_and_to_commit_from_filename(latest_st_ops_file_name)
      end

      # Computes the path for the next st-ops file
      # @param st_ops_dir [String] path to directory that contains all st-ops files
      # @param from_commit [String] sha1 hash of from-commit
      # @param to_commit [String] sha1 hash of to-commit
      # @param time_override [DateTime, optional] for testing
      def self.compute_next_file_path(st_ops_dir, from_commit, to_commit, time_override=nil)
        File.join(
          st_ops_dir,
          [
            'st-ops-',
            compute_next_file_sequence_marker(st_ops_dir, time_override),
            '-',
            compute_from_to_git_commit_marker(from_commit, to_commit),
            '.json'
          ].join
        )
      end

      # Computes the next sequence marker for subtitle_operations files.
      # We use a UTC date/time stamp for sequencing.
      # @param st_ops_dir [String] path to the folder containing st-ops files
      # @param time_override [DateTime, optional] for testing
      # @return [String] with date/time stamp in the following format:
      #     "2016_07_12-20_39_28" (UTC)
      def self.compute_next_file_sequence_marker(st_ops_dir, time_override=nil)
        current_utc_time_stamp = (time_override || Time.now.utc).strftime('%Y_%m_%d-%H_%M_%S')
        existing_st_ops_file_names = get_all_st_ops_files(st_ops_dir)
        if existing_st_ops_file_names.any? { |e| e.index(current_utc_time_stamp) }
          raise "Duplicate timestamp #{ current_utc_time_stamp.inspect }. Please try again."
        else
          current_utc_time_stamp
        end
      end

      # Returns absolute file path to st-ops file for from_commit and to_commit
      # if it exists. Otherwise nil.
      # @param st_ops_dir [String] path to the folder containing st-ops files
      # @param from_commit [String] sha1 hash of from-commit
      # @param to_commit [String] sha1 hash of to-commit
      # @return [String, nil] the absolute path to existing file or nil.
      def self.detect_st_ops_file_path(st_ops_dir, from_commit, to_commit)
        Dir.glob(
          File.join(
            st_ops_dir,
            "st-ops-*-#{ compute_from_to_git_commit_marker(from_commit, to_commit) }.json"
          )
        ).first
      end

      # Extracts from and to git commits from an st ops filename.
      # @param filename [String] absolute path to file in the following format:
      #        "/some/path/st-ops-2016_07_12-20_39_28-123456-to-654321.json"
      # @return [Array<String>] tuple of from and to git commit sha1 (first 6 chars)
      def self.extract_from_and_to_commit_from_filename(filename)
        match = filename.match(/([\h]{6})-to-([\h]{6})\.json\z/)
        from_commit, to_commit = match[1], match[2]
        [from_commit, to_commit]
      end

      # Finds the path of the earliest st-ops file if any exist
      # @param st_ops_dir [String]
      # @return [String, Nil]
      def self.find_earliest(st_ops_dir)
        get_all_st_ops_files(st_ops_dir).first
      end

      # Finds the path of the latest st-ops file if any exist
      # @param st_ops_dir [String]
      # @return [String, Nil]
      def self.find_latest(st_ops_dir)
        get_all_st_ops_files(st_ops_dir).last
      end

      # Returns an array of absolute paths for all st_ops files in st_ops_dir.
      # @param st_ops_dir [String]
      # @return [Array<String>]
      def self.get_all_st_ops_files(st_ops_dir)
        Dir.glob(File.join(st_ops_dir, "st-ops-*.json"))
      end

      # Returns array of sync commits based on files found in the st-ops folder.
      # start_with_commit can optionally be specified and defaults to the very
      # first `from` commit.
      # @param st_ops_dir [String] path to the folder containing st-ops files
      # @param start_with_commit [String, optional]
      # @return [Array<String>] first 6 characters of each commit's sha1
      def self.get_sync_commits(st_ops_dir, start_with_commit=nil)
        all_sync_commits = get_all_st_ops_files(st_ops_dir).map { |e|
          extract_from_and_to_commit_from_filename(e)
        }.flatten.uniq

        if start_with_commit
          sanitized_start_with_commit = truncate_git_commit_sha1(start_with_commit)
          include_following_commits = false
          r = all_sync_commits.find_all { |e|
            # Find all commits from start_with_commit forward
            include_following_commits ||= (e == sanitized_start_with_commit)
          }
          if r.empty?
            raise "Could not find start commit #{ start_with_commit.inspect }.".color(:red)
          end
        else
          r = all_sync_commits
        end
        r
      end

      # Returns truncated copy of gc_sha1 fit for st-ops file names.
      # @param gc_sha1 [String]
      # @return [String]
      def self.truncate_git_commit_sha1(gc_sha1)
        gc_sha1.first(6)
      end
    end
  end
end
