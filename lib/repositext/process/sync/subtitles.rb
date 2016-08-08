# encoding UTF-8
class Repositext
  class Process
    class Sync

      # Synchronizes subtitles from English to foreign repos.
      #
      class Subtitles

        class ReposNotReadyError < StandardError; end
        class InvalidInputDataError < StandardError; end

        include EnsureAllContentReposAreReady
        include ExtractOrLoadPrimarySubtitleOperations
        include FinalizeSyncOperation
        include TransferSubtitleOperationsToForeignRepos
        include UpdatePrimarySubtitleMarkerCsvFiles

        # Initialize a new subtitle sync process
        # @param options [Hash] with stringified keys
        # @option options [Config] 'config'
        # @option options [Array<String>] 'file_list'
        # @option options [String, Nil] 'from-commit', optional, defaults to previous `to-commit`
        # @option options [Repository] 'repository' the primary repo
        # @option options [IO] stids_inventory_file
        # @option options [String, Nil] 'to-commit', optional, defaults to most recent local git commit
        def initialize(options)
          @config = options['config']
          @file_list = options['file_list']
          @from_git_commit = options['from-commit']
          @repository = options['repository']
          @stids_inventory_file = options['stids_inventory_file']
          @to_git_commit = options['to-commit']
        end

        def sync
          @from_git_commit, @to_git_commit = compute_bounding_git_commits(
            @from_git_commit,
            @to_git_commit,
            @config,
            @repository
          )
          if @from_git_commit == @to_git_commit
            raise "Subtitles are up-to-date, nothing to sync!"
          end

          # ensure_all_content_repos_are_ready
          st_ops_for_repo = extract_or_load_primary_subtitle_operations
          update_primary_subtitle_marker_csv_files(
            @repository,
            st_ops_for_repo
          )
          # transfer_subtitle_operations_to_foreign_repos(st_ops_for_repo)
          finalize_sync_operation(@repository, @to_git_commit)
        end

      private

        # Computes `from` and `to` git commits
        # @param from_g_c_override [String, nil]
        # @param to_g_c_override [String, nil]
        # @param config [Config]
        # @param repo [Repository]
        # @return [Array<String>] the `from` and `to` git commit sha1 strings
        def compute_bounding_git_commits(from_g_c_override, to_g_c_override, config, repo)
          from_git_commit = compute_from_commit(from_g_c_override, config, repo)
          to_git_commit = compute_to_commit(to_g_c_override, repo)
          [from_git_commit, to_git_commit]
        end

        # Computes the `from` commit
        # @param commit_sha1_override [String, Nil]
        # @param config [Repositext::Cli::Config]
        # @param repository [Repository]
        def compute_from_commit(commit_sha1_override, config, repository)
          # Use override if given
          if '' != (o = commit_sha1_override.to_s)
            return o
          end
          # Load from repository's data.json file
          from_setting = repository.read_repo_level_data['subtitles_last_synched_at_git_commit']
          raise "Missing subtitles_last_synched_at_git_commit datum"  if from_setting.nil?
          # Load from latest st-ops file
          from_latest_st_ops_file = compute_to_commit_from_latest_st_ops_file(
            find_latest_st_ops_file_path(config.base_dir(:subtitle_operations_dir))
          )
          # Verify that setting and file name are consistent
          if from_latest_st_ops_file && from_setting.first(6) != from_latest_st_ops_file
            raise "Inconsistent from_git_commit: Setting is #{ from_setting.inspect } and latest st-ops file is #{ from_latest_st_ops_file }"
          end
          # Return consistent value from setting
          from_setting
        end

        # Finds the path of the latest st-ops file if any exist
        # @param st_ops_dir [String]
        # @return [String, Nil]
        def find_latest_st_ops_file_path(st_ops_dir)
          latest_st_ops_file_name = Dir.glob(
            File.join(st_ops_dir, "st-ops-*.json")
          ).last
        end

        # Returns the `to` git commit from the latest st-ops file if any exist.
        # @param latest_st_ops_file_name [String, Nil]
        # @return [String, Nil]
        def compute_to_commit_from_latest_st_ops_file(latest_st_ops_file_name)
          return nil  if latest_st_ops_file_name.nil?
          # Extract `from` commit from file name (e.g., st-ops-00001-791a1d-to-eea8b4.json)
          from_commit = latest_st_ops_file_name.match(
            /st-ops-\d+-[^\-]+-to-([^\.]+).json\z/
          )[1]
        end

        # Computes the `to` commit
        # @param commit_sha1_override [String, Nil]
        # @param repository [Repositext::Repository]
        def compute_to_commit(commit_sha1_override, repository)
          # Use override if given
          if '' != (o = commit_sha1_override.to_s)
            return o
          end
          # Use latest commit from repository
          repository.latest_commit_sha_local
        end

      end
    end
  end
end
