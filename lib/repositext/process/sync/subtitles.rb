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
        include FinalizeSyncOperation
        include SyncForeignFile
        include SyncForeignRepo
        include SyncPrimaryFile
        include SyncPrimaryRepo

        # Initialize a new subtitle sync process
        # @param options [Hash] with stringified keys
        # @option options [Config] 'config'
        # @option options [Array<String>] 'file_list' can be used at command
        #                                 line via file-selector to limit which
        #                                 files should be synced.
        # @option options [String, Nil] 'from-commit', optional, defaults to previous `to-commit`
        # @option options [Repository] 'primary_repository' the primary repo
        # @option options [IO] stids_inventory_file
        # @option options [String, Nil] 'to-commit', optional, defaults to most recent local git commit
        def initialize(options)
          @config = options['config']
          @file_list = options['file_list']
          @from_git_commit = options['from-commit']
          @primary_repository = options['primary_repository']
          @stids_inventory_file = options['stids_inventory_file']
          @to_git_commit = options['to-commit']

          # Init caches

          # Cache for Subtitle::OperationsForRepository.
          # See #cached_st_ops_for_repo for details.
          @st_ops_cache = {}
          # Cache for primary files (content AT and STM CSV) at various git
          # commits. See #cached_primary_file_data for details.
          @primary_subtitle_data_cache = {}
          # Container for any files that could not be synced. Array of Hashes:
          # [{ file: <RFile::ContentAt>, message: <String> },...]
          @unprocessable_files = []
        end

        def sync
          puts
          puts "Syncronizing subtitles".color(:blue)
          puts
          puts " - Ensure all content repos are ready".color(:blue)

          puts " - Compute 'to_git_commit':".color(:blue)
          @to_git_commit = compute_to_git_commit(@to_git_commit, @primary_repository)
          puts "   - #{ @to_git_commit.inspect }"

          # Syncronize primary repo if required
          puts " - Sync primary repo '#{ @primary_repository.name }'".color(:blue)
          if @primary_repository.read_repo_level_data['st_sync_required']
            sync_primary_repo
          else
            puts "   - skip, repo is up-to-date."
          end

          # Compute earliest global `from` git commit. No sync may go before this commit.
          @earliest_from_git_commit = @primary_repository.lookup(
            Subtitle::OperationsFile.compute_earliest_from_commit(
              @config.base_dir(:subtitle_operations_dir)
            )
          )

          # Syncronize all foreign repos that participate in st sync
          all_synced_foreign_repos.each do |foreign_repo|
            puts " - Sync foreign repo '#{ foreign_repo.name }'".color(:blue)
            sync_foreign_repo(foreign_repo)
          end

          puts " - Finalize sync operation".color(:blue)
          finalize_sync_operation
        end

      private

        # Returns an array of foreign repos that have `st_sync_active` set to true.
        # @return [Array<Repository>]
        def all_synced_foreign_repos
          RepositorySet.new(
            @primary_repository.parent_dir
          ).all_repos(
            :foreign_content_repos
          ).find_all { |foreign_repo|
            foreign_repo.read_repo_level_data['st_sync_active']
          }
        end

        # Returns primary subtitle data given a content_at_file, a git_commit,
        # and a commit_reference.
        # Data is stored in a nested Hash in the @primary_subtitle_data_cache i_var:
        #     {
        #       'pid-12345' => {
        #         'gc-123456' => {
        #           at_commit: [
        #             <#Repositext::Subtitle ...>,
        #           ],
        #         },
        #       },
        #       <product_identity_id> => {
        #         <git_commit_sha1 (first 6)> => {
        #           Symbol: [
        #             <Repositext::Subtitle>
        #           ]
        #         }
        #       }
        #     }
        # @param content_at_file [RFile::ContentAt] from any repo (primary or foreign)
        # @param git_commit_sha1 [String] complete or first six only
        # @param commit_reference [Symbol] Note: for from_subtitles we want the
        #        file contents at the commit (:at_commit), however for to_subtitles
        #        we want the file contents as of the next commit after
        #        git_commit_sha1 (:at_next_commit).
        # @return [Array]
        def cached_primary_subtitle_data(content_at_file, git_commit_sha1, commit_reference)
          pii_cache_key = content_at_file.extract_product_identity_id
          gc_cache_key = Subtitle::OperationsFile.truncate_git_commit_sha1(git_commit_sha1)
          ref_cache_key = commit_reference

          if(cached_product_identity_id = @primary_subtitle_data_cache[pii_cache_key])
            if(cached_git_commit = cached_product_identity_id[gc_cache_key])
              if(cached_commit_ref = cached_git_commit[ref_cache_key])
                # Return cached data
                return cached_commit_ref
              end
            end
          end

          # Data is not in cache yet, retrieve from disk
          primary_content_at_file = content_at_file.corresponding_primary_file
          stm_csv_file = primary_content_at_file.corresponding_subtitle_markers_csv_file
                                                .as_of_git_commit(
                                                  git_commit_sha1,
                                                  commit_reference
                                                )
          # Store data in cache and return it
          @primary_subtitle_data_cache[pii_cache_key] ||= {}
          @primary_subtitle_data_cache[pii_cache_key][gc_cache_key] ||= {}
          @primary_subtitle_data_cache[pii_cache_key][gc_cache_key][ref_cache_key] = stm_csv_file.subtitles
        end

        # Returns st_ops_for_repo given a from and to git commit.
        # Any ops that are not in the cache yet will be retrieved by calling
        # st_ops_generator block and added to cache.
        # Caches st_ops in memory in a hash with [from_git_commit, to_git_commit]
        # (first 6 chars only) as keys in the @st_ops_cache i_var:
        #     {
        #       ['123456', '654321'] => <#Subtitle::OperationsForRepository ...>,
        #       [<from_git_commit>, <to_git_commit>] => Subtitle::OperationsForRepository,
        #     }
        # @param repository [Repository]
        # @param from_git_commit [String]
        # @param to_git_commit [String]
        # @param st_ops_generator [Proc], expected to return Subtitle::OperationsForRepository
        # @return [Subtitle::OperationsForRepository] either from cache or generator
        def cached_st_ops_for_repo(repository, from_git_commit, to_git_commit, &st_ops_generator)
          cache_key = [from_git_commit, to_git_commit].map { |e|
            Subtitle::OperationsFile.truncate_git_commit_sha1(e)
          }
          if(cached_st_ops = @st_ops_cache[cache_key])
            # Return cached data
            return cached_st_ops
          end

          # Data is not cached yet, generate, cache and return it.
          @st_ops_cache[cache_key] = yield
        end

        # Computes the `to` commit
        # @param commit_sha1_override [String, Nil]
        # @param primary_repository [Repositext::Repository]
        def compute_to_git_commit(commit_sha1_override, primary_repository)
          # Use override if given
          return o  if '' != (o = commit_sha1_override.to_s)

          # Otherwise use latest commit from primary_repository
          primary_repository.latest_commit_sha_local
        end

        def verbose_logging
          true
        end

      end
    end
  end
end
