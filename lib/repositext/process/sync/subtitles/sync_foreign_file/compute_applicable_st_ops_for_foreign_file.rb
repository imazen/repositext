class Repositext
  class Process
    class Sync
      class Subtitles
        module SyncForeignFile
          # This namespace provides methods related to computing subtitle operations
          # that are relevant for a foreign file.
          module ComputeApplicableStOpsForForeignFile

            extend ActiveSupport::Concern

          private

            # Returns a list of all Subtitle::OperationsForFile that cover the
            # range from `file_from_git_commit` to `@to_git_commit`.
            # Caches Subtitle::OperationsForRepository for all encountered sync
            # boundaries.
            # @param foreign_content_at_file [RFile::ContentAt]
            # @param file_from_git_commit [String] SHA1
            # @param ffgc_source [Symbol] source of ffgc, e.g., :file_level_data,
            #     :subtitle_export, or :autosplit
            # @return [Outcome] with [Array<Subtitle::OperationsForFile>] as result
            def compute_applicable_st_ops_for_foreign_file(
              foreign_content_at_file,
              file_from_git_commit,
              ffgc_source
            )
              begin
                applicable_st_ops_for_file = if @to_git_commit == file_from_git_commit
                  # Return empty array if file is already synced to newest.
                  print ", no st-ops to transfer"
                  []
                elsif(
                  :file_level_data == ffgc_source ||
                  aligned_with_st_ops_file_boundaries?(file_from_git_commit)
                )
                  # Sync boundaries are aligned with existing st-ops files.
                  applicable_st_ops_for_repo = load_applicable_st_ops_for_repo_from_existing_files(
                    file_from_git_commit
                  )
                  # Extract st_ops_for_file
                  product_identity_id = foreign_content_at_file.extract_product_identity_id
                  applicable_st_ops_for_repo.map { |st_ops_for_repo|
                    st_ops_for_repo.get_operations_for_file(product_identity_id)
                  }.compact
                else
                  # Sync boundaries are not aligned with existing st-ops files.
                  compute_custom_st_ops_for_file(
                    file_from_git_commit,
                    @to_git_commit,
                    foreign_content_at_file.corresponding_primary_file
                  )
                end
                Outcome.new(true, applicable_st_ops_for_file, [])
              rescue Process::Compute::SubtitleOperationsForFile::ComputeSubtitleAttrs::MismatchingSubtitleCountsError => e
                Outcome.new(false, nil, [e.message])
              rescue Process::Compute::SubtitleOperationsForFile::ComputeSubtitleAttrs::EncounteredNilStidError => e
                Outcome.new(false, nil, [e.message])
              end
            end

            # Returns true if git_commit_sha1 is aligned with an st-ops file commit
            # boundary (either `from` or `to`)
            # @param git_commit_sha1 [String] can be full or partial SHA1
            def aligned_with_st_ops_file_boundaries?(git_commit_sha1)
              # Does an st-ops file exist with git_commit_sha1 as one of the
              # commit boundaries?
              Subtitle::OperationsFile.any_with_git_commit?(
                @config.base_dir(:subtitle_operations_dir),
                git_commit_sha1
              )
            end

            # Loads all applicable st_ops_for_repo from existing st_ops files using
            # the st_ops_cache. This is used for foreign files' ongoing syncs.
            # @param file_from_git_commit [String] SHA1
            # @return [Array<Subtitle::OperationsForRepository>]
            def load_applicable_st_ops_for_repo_from_existing_files(file_from_git_commit)
              # Get all sync_commits starting with file_from_git_commit
              applicable_sync_commits = Subtitle::OperationsFile.get_sync_commits(
                @config.base_dir(:subtitle_operations_dir),
                file_from_git_commit
              )
              print ", load existing st-ops for the following sync_commits: #{ applicable_sync_commits.inspect }"
              applicable_sync_commits.each_cons(2).map { |l_from_git_commit, l_to_git_commit|
                cached_st_ops_for_repo(
                  @primary_repository,
                  l_from_git_commit,
                  l_to_git_commit
                ) do
                  # This block is called if this st_ops_for repo is not in @st_ops_cache
                  st_ops_path = Subtitle::OperationsFile.detect_st_ops_file_path(
                    @config.base_dir(:subtitle_operations_dir),
                    l_from_git_commit,
                    l_to_git_commit
                  )
                  Subtitle::OperationsForRepository.from_json(
                    File.read(st_ops_path),
                    @primary_repository.base_dir
                  )
                end
              }
            end

            # Computes custom temporary Subtitle::OperationsForFile for
            # the given sync boundaries and primary file. This is used for
            # foreign files' initial syncs.
            # @param l_from_git_commit [String]
            # @param l_to_git_commit [String]
            # @param primary_content_at_file [RFile::ContentAt] as of `to` git commit
            # @return [Array<Subtitle::OperationsForFile>]
            def compute_custom_st_ops_for_file(l_from_git_commit, l_to_git_commit, primary_content_at_file)
              print ", compute custom st-ops between #{ l_from_git_commit.inspect } and #{ l_to_git_commit.inspect }"
              st_ops_for_file = cached_st_ops_for_file(
                primary_content_at_file,
                l_from_git_commit,
                l_to_git_commit
              ) do
                # This block is called if this st_ops_for file is not in @st_ops_cache
                puts "\n" # Adapt logging to handle output from called code
                Repositext::Process::Compute::SubtitleOperationsForFile.new(
                  primary_content_at_file,
                  primary_content_at_file.repository.base_dir,
                  {
                    from_git_commit: l_from_git_commit,
                    to_git_commit: l_to_git_commit,
                    prev_last_operation_id: -1,
                  }
                ).compute
              end
              [st_ops_for_file]
            end
          end
        end
      end
    end
  end
end
