class Repositext
  class Process
    class Sync

      # Synchronizes subtitles from English to foreign repos.
      # * Extracts subtitle operations in primary repo
      # * Transfers subtitle operations to foreign repos where applicable
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
        # @option options [Config] The primary repo's config
        # @option options [Array<String>] 'file_list' can be used at command
        #                                 line via file-selector to limit which
        #                                 files should be synced.
        # @option options [String, Nil] 'from-commit', optional, defaults to
        #   previous `to-commit`. NOTE: If you override this, always provide the
        #   recorded git commit. The software will then use content as of the
        #   next commit after the specified one to get the changes effected by
        #   the sync operation.
        # @option options [Repository] 'primary_repository' the primary repo
        # @option options [IO] stids_inventory_file
        # @option options [String, Nil] 'to-commit', optional, computed if not
        #   given. NOTE: See Note at 'from-commit'
        def initialize(options)
          @config = options['config']
          @file_list = options['file_list']
          @last_operation_id = options['last_operation_id']
          @from_git_commit = options['from-commit']
          @primary_repository = options['primary_repository']
          @stids_inventory_file = options['stids_inventory_file']
          @to_git_commit = options['to-commit']
          @is_initial_primary_sync = options['is_initial_primary_sync']

          # Init caches

          # Cache for Subtitle::OperationsForRepository.
          # See #cached_st_ops_for_repo for details.
          @st_ops_cache_repo = {}
          # See #cached_st_ops_for_file for details.
          @st_ops_cache_file = {}
          # Cache for primary files (content AT and STM CSV) at various git
          # commits. See #cached_primary_file_data for details.
          @primary_subtitle_data_cache = {}
          # Container for any files that could not be synced. Array of Hashes:
          # [{ file: <RFile::ContentAt>, message: <String> },...]
          @unprocessable_files = []
          # Container for any files that raised an exception during autosplit. Array of Hashes:
          # [{ file: <RFile::ContentAt>, message: <String> },...]
          @files_with_autosplit_exceptions = []
          # Container for any files that were synced successfully. Array of Strings
          # ['content/53/spn53-0504.at', ...]
          @successful_files_with_autosplit = []
          @successful_files_with_st_ops = []
          @successful_files_without_st_ops = []
          # Container for any files that were autosplit, grouped by language
          # { eng: ['54-0403', '65-0101'] }
          @auto_split_files_collector = Hash.new([])
        end

        def sync
          puts
          puts "Synchronizing subtitles".color(:blue)
          puts
          puts " - Ensure all content repos are ready".color(:blue)
          # TODO: Should we do this on a per-repo basis? check for primary here, and then
          # each foreign separately?
          # ensure_all_content_repos_are_ready

          puts " - Compute 'to_git_commit':".color(:blue)
          compute_to_git_commit!(@to_git_commit, @primary_repository)
          puts "   - #{ @to_git_commit.inspect }"

          # Syncronize primary repo if required
          puts " - Sync primary repo '#{ @primary_repository.name }'".color(:blue)

          if @primary_repository.read_repo_level_data['st_sync_required']
            sync_primary_repo
          else
            puts "   - skip, repo is up-to-date."
          end

          # Compute earliest global `from` git commit. No sync may go before
          # this commit.
          @earliest_from_git_commit = @primary_repository.lookup(
            Subtitle::OperationsFile.compute_earliest_from_commit(
              @config.base_dir(:subtitle_operations_dir)
            )
          )

          begin
            if !@is_initial_primary_sync
              # Syncronize all foreign repos that participate in st sync
              all_synced_foreign_repos.each do |foreign_repo|
                puts " - Sync foreign repo '#{ foreign_repo.name }'".color(:blue)
                sync_foreign_repo(foreign_repo)
              end
            end
          ensure
            puts
            puts " - Finalize sync operation".color(:blue)
            finalize_sync_operation
            puts "\n"
            if @auto_split_files_collector.any?
              puts "File selectors for autosplit files:".color(:blue)
              @auto_split_files_collector.each { |lang_code, date_codes|
                dcs = date_codes.map { |e| "#{ e }_" }.join(',')
                puts "#{ lang_code }: **/*{#{ dcs }}*"
              }
            else
              puts "No files were autosplit.".color(:blue)
            end
          end
        end

        # Public Bang! wrapper around compute_to_git_commit to assign the instance
        # variable.
        def compute_to_git_commit!(commit_sha1_override, primary_repository)
          @to_git_commit = compute_to_git_commit(commit_sha1_override, primary_repository)
        end

      private

        # Returns an array of foreign repos that have `st_sync_active` setting
        # set to true.
        # @return [Array<Repository>]
        def all_synced_foreign_repos
          RepositorySet.new(
            @primary_repository.parent_dir
          ).all_repos(
            :foreign_content_repos
          ).find_all { |foreign_repo|
            foreign_repo.read_repo_level_settings['st_sync_active']
          }
        end

        # Returns primary subtitle data given a content_at_file, a git_commit,
        # and a relative_version.
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
        # @param relative_version [Symbol] Note: for from_subtitles we want the
        #        file contents at the commit (:at_ref_or_nil), however for to_subtitles
        #        we want the file contents as of the next commit after
        #        git_commit_sha1 (:at_child_or_current).
        # @return [Array]
        def cached_primary_subtitle_data(content_at_file, git_commit_sha1, relative_version)
          pii_cache_key = content_at_file.extract_product_identity_id
          gc_cache_key = Subtitle::OperationsFile.truncate_git_commit_sha1(git_commit_sha1)
          ref_cache_key = relative_version

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
                                                  relative_version
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
        # (first 6 chars only) as keys in the @st_ops_cache_repo i_var:
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
          if(cached_st_ops = @st_ops_cache_repo[cache_key])
            # Return cached data
            return cached_st_ops
          end

          # Data is not cached yet, generate, cache and return it.
          @st_ops_cache_repo[cache_key] = yield
        end

        # Returns st_ops_for_file given a from, to git commit and a primary file's
        # product_identity_id.
        # Any ops that are not in the cache yet will be retrieved by calling
        # st_ops_generator block and added to cache.
        # Caches st_ops in memory in a hash with
        # [from_git_commit, to_git_commit][product_identity_id]
        # (first 6 chars only) as keys in the @st_ops_cache_file i_var:
        #     {
        #       ['123456', '654321'] => {
        #         '1234' => <#Subtitle::OperationsForFile ...>,
        #         ...
        #       },
        #       [<from_git_commit>, <to_git_commit>] => {
        #         <product_identity_id> => Subtitle::OperationsForFile,
        #         ...
        #       },
        #     }
        # @param primary_content_at_file [RFile::ContentAt]
        # @param from_git_commit [String]
        # @param to_git_commit [String]
        # @param st_ops_generator [Proc], expected to return Subtitle::OperationsForFile
        # @return [Subtitle::OperationsForFile] either from cache or generator
        def cached_st_ops_for_file(primary_content_at_file, from_git_commit, to_git_commit, &st_ops_generator)
          primary_cache_key = [from_git_commit, to_git_commit].map { |e|
            Subtitle::OperationsFile.truncate_git_commit_sha1(e)
          }
          secondary_cache_key = primary_content_at_file.extract_product_identity_id
          if(cached_st_ops = (@st_ops_cache_file[primary_cache_key] ||= {})[secondary_cache_key])
            # Return cached data
            return cached_st_ops
          end

          # Data is not cached yet, generate, cache and return it.
          @st_ops_cache_file[primary_cache_key][secondary_cache_key] = yield
        end

        # Computes the `to` commit that will be used for all primary and
        # foreign files. The returned commit is guaranteed to be
        # aligned with the `to-git-commit` of the latest st_ops file.
        # This will make sure that all foreign files are synced to st_sync
        # git commits, and we can use st_ops files to extract and transfer
        # subtitle operations.
        # The latest st_ops file may already exist (if primary has not
        # st_sync_required) or may get created with latest primary git commit
        # (if primary has st_sync_required).
        # @param commit_sha1_override [String, Nil]
        # @param primary_repository [Repositext::Repository]
        # @return [String] the sha1 of the commit
        def compute_to_git_commit(commit_sha1_override, primary_repository)
          # Use override if given
          return commit_sha1_override  if '' != commit_sha1_override.to_s.strip

          if @primary_repository.read_repo_level_data['st_sync_required']
            # We're going to sync primary and create a new st_ops file with
            # the latest git commit as `to_git_commit`
            primary_repository.latest_commit_sha_local
          else
            # No st_sync on primary required, use the `to_git_commit` of the
            # latest st_ops file in primary repo
            # Load `from` and `to` commits from latest st-ops file as array,
            # return last item (`to` commit).
            truncated_sha1 = Subtitle::OperationsFile.compute_latest_from_and_to_commits(
              @config.base_dir(:subtitle_operations_dir)
            ).last
            @primary_repository.expand_commit_sha1(truncated_sha1)
          end
        end

      end
    end
  end
end
