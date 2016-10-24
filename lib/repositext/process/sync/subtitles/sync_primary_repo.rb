# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module SyncPrimaryRepo

          extend ActiveSupport::Concern

          # Syncronizes subtitle operations in the primary repo
          def sync_primary_repo
            puts "   - Compute `from_git_commit`:"
            @from_git_commit = compute_primary_from_git_commit(
              @from_git_commit,
              @config,
              @primary_repository
            )
            puts "     - #{ @from_git_commit.inspect }"
            st_ops_for_repo = extract_and_persist_primary_subtitle_operations

            puts "   - Sync primary files (update STM CSV and file level st_sync data):"
            files_to_sync = if @is_initial_sync
              # For the initial sync we include all files. This is required so that we
              # restore the STM CSV files to have all columns even for those files that
              # have no subtitle operations
              content_type = ContentType.all(@primary_repository).last
              Dir.glob(
                File.join(content_type.base_dir, '**/content/**/*.at')
              ).map { |absolute_file_path|
                # Skip non content_at files
                unless absolute_file_path =~ /\/content\/.+\d{4}\.at\z/
                  raise "shouldn't get here"
                end
                Repositext::RFile::ContentAt.new(
                  File.read(absolute_file_path),
                  content_type.language,
                  absolute_file_path,
                  content_type
                )
              }
            else
              # On subsequent syncs we only process affected files
              st_ops_for_repo.affected_content_at_files
            end

            files_to_sync.each do |content_at_file|
              sync_primary_file(content_at_file, st_ops_for_repo)
            end

            update_primary_repo_level_st_sync_data(st_ops_for_repo.next_operation_id)
          end

        private

          # Extracts subtitle operations for entire repo between two git commits.
          # @return [Subtitle::OperationsForRepository] the name of the file operations are stored in
          def extract_and_persist_primary_subtitle_operations
            # Extract primary subtitle operations
            puts "   - Extract subtitle operations"
            subtitle_ops = []
            # Pick any content_type, doesn't matter which one
            content_type = ContentType.all(@primary_repository).first
            subtitle_ops = Repositext::Process::Compute::SubtitleOperationsForRepository.new(
              content_type,
              @from_git_commit,
              @to_git_commit,
              @file_list,
              @is_initial_sync
            ).compute

            puts "   - Assign new subtitle ids"
            json_with_temp_stids = subtitle_ops.to_json.to_s
            json_with_persistent_stids = replace_temp_with_persistent_stids!(
              json_with_temp_stids,
              @stids_inventory_file
            )

            st_ops_file_path = Subtitle::OperationsFile.compute_next_file_path(
              @config.base_dir(:subtitle_operations_dir),
              @from_git_commit,
              @to_git_commit
            )
            puts "   - Write st-ops file to #{ st_ops_file_path }"
            persist_primary_st_ops!(st_ops_file_path, json_with_persistent_stids)

            # Now we read back the JSON so that we get st_ops with new stids
            st_ops = Subtitle::OperationsForRepository.from_json(
              json_with_persistent_stids,
              @primary_repository.base_dir
            )
          end

          # @param next_operation_id [Integer]
          def update_primary_repo_level_st_sync_data(next_operation_id)
            # Record git_to_commit at primary repo level
            @primary_repository.update_repo_level_data(
              'st_sync_commit' => @to_git_commit,
              'st_sync_required' => nil,
              'st_sync_next_operation_id' => next_operation_id,
            )
          end

          # Computes the `from` git commit's SHA1 for primary repo.
          # @param commit_sha1_override [String, Nil]
          # @param config [Repositext::Cli::Config]
          # @param primary_repository [Repository]
          # @return [String]
          def compute_primary_from_git_commit(commit_sha1_override, config, primary_repository)
            # Use override if given
            return o  if '' != (o = commit_sha1_override.to_s)

            # Load from primary_repository's data.json file
            from_repo_level_data = primary_repository.read_repo_level_data['st_sync_commit']
            raise "Missing st_sync_commit datum".color(:red)  if from_repo_level_data.nil?

            # Load `from` and `to` commits from latest st-ops file as array
            from_latest_st_ops_file = Subtitle::OperationsFile.compute_latest_from_and_to_commits(
              config.base_dir(:subtitle_operations_dir)
            )
            # Verify that setting and file name are consistent, either `from` or `to`
            # commit. If repo_level_data is consistent with `from` commit, then the st-ops
            # file already exists and we'll re-use it. If setting is consistent
            # with `to` commit, then st-ops file doesn't exist yet and we'll
            # create it.
            if(
              from_latest_st_ops_file.any? &&
              !from_latest_st_ops_file.include?(
                Subtitle::OperationsFile.truncate_git_commit_sha1(from_repo_level_data)
              )
            )
              raise([
                "Inconsistent from_git_commit: repo level data is #{ from_repo_level_data.inspect }",
                "and latest st-ops file has `from` and `to` commits #{ from_latest_st_ops_file.inspect }"
              ].join(' ').color(:red))
            end
            # Return consistent value from setting
            from_repo_level_data
          end

          # Persists st-ops to file
          # @param st_ops_file_path [String]
          # @param st_ops_json [String]
          def persist_primary_st_ops!(st_ops_file_path, st_ops_json)
            File.open(st_ops_file_path, 'w') { |f| f.write(st_ops_json) }
          end

          # Replaces all temp stids with persistent ones in json string
          # @param json_string [String] the original json string with temp stids
          # @param stids_inventory_file [IO]
          # @return [String] a copy of json_string with all temp stids replaced
          def replace_temp_with_persistent_stids!(json_string, stids_inventory_file)
            new_json_string = json_string.dup
            # Find all temp stids: "stid": "tmp-1867814+1"
            all_temp_stids = new_json_string.scan(/(?<="stid": ")tmp-[\d\+]+(?=",\n)/).uniq
            # Generate new stids
            new_stids = Repositext::Subtitle::IdGenerator.new(
              stids_inventory_file
            ).generate(
              all_temp_stids.length
            ).shuffle

            # Replace temp stids
            all_temp_stids.each { |temp_stid|
              new_stid = new_stids.shift
              raise "Handle this: #{ new_subtitles.inspect }"  if new_stid.nil?
              new_json_string.gsub!(temp_stid, new_stid)
            }
            new_json_string
          end
        end
      end
    end
  end
end
