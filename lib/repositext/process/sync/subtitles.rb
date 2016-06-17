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
        include TransferSubtitleOperationsToForeignRepos
        include UpdatePrimarySubtitleMarkerCsvFiles

        # Initialize a new subtitle sync process
        # @option [IO] 'stids_inventory_file'
        def initialize(options)
          @config = options['config']
          @content_type = options['content_type']
          @file_list = options['file_list']
          @from_git_commit = options['from-commit']
          @repository = options['repository']
          @stids_inventory_file = options['stids_inventory_file']
          @to_git_commit = options['to-commit']
        end

        def sync
          ensure_all_content_repos_are_ready
          @from_git_commit = compute_from_commit(@from_git_commit, @config)
          @to_git_commit = compute_to_commit(@to_git_commit, @content_type.repository)
          st_ops_for_repo = extract_or_load_primary_subtitle_operations
          update_primary_subtitle_marker_csv_files(
            @repository.base_dir,
            @content_type,
            st_ops_for_repo
          )
          # transfer_subtitle_operations_to_foreign_repos
        end

      private

        # Computes the `from` commit
        # @param commit_sha1_override [String, Nil]
        # @param config [Repositext::Cli::Config]
        def compute_from_commit(commit_sha1_override, config)
          # Use override if given
          if '' != (o = commit_sha1_override.to_s)
            return o
          end
          # load from repository's data.json file, will raise if not present.
          config.setting(:subtitles_last_synched_at_git_commit)
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
