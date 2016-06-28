# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module TransferSubtitleOperationsToForeignRepos

          extend ActiveSupport::Concern

          # @param st_ops_for_repo [Subtitle::OperationsForRepo]
          def transfer_subtitle_operations_to_foreign_repos(st_ops_for_repo)
            puts
            puts "Transferring subtitle operations to foreign repos"
            # Iterate over all files that have subtitle changes
            files_flagged_for_manual_review = []
            st_ops_for_repo.operations_for_files.each do |st_ops_for_file|
              # Compute all data related to the to_primary_content_at_file
              to_primary_content_at_file = st_ops_for_file.content_at_file
              puts " - primary file: #{ to_primary_content_at_file.basename }"
              to_stm_csv_file = to_primary_content_at_file.corresponding_subtitle_markers_csv_file
              to_subtitles = to_stm_csv_file.subtitles
              to_subtitles_count = to_subtitles.length
              from_stm_csv_file = to_stm_csv_file.as_of_git_commit(@from_git_commit)
              from_subtitles = from_stm_csv_file.subtitles
              from_subtitles_count = from_subtitles.length
              st_ops_count_delta = st_ops_for_file.subtitles_count_delta
              st_review_flags = st_ops_for_file.operations.inject({}) { |m,st_op|
                m[st_op.salient_subtitle.persistent_id] = st_op.operationType
                m
              }

              # iterate over all foreign repositories
              RepositorySet.new(
                @repository.parent_dir
              ).all_repos(
                :foreign_content_repos
              ).each do |foreign_repo|
                puts "   - repo: #{ foreign_repo.name }"
                # iterate over all content_types
                ContentType.all(foreign_repo).each do |foreign_content_type|
                  puts "     - content type: #{ foreign_content_type.name }"
                  # find corresponding foreign content_at file
                  foreign_content_at_file = RFile::ContentAt.find_by_product_identity_id(
                    to_primary_content_at_file.extract_product_identity_id,
                    foreign_content_type
                  )
                  next  if foreign_content_at_file.nil?
                  puts "       - foreign content_at file: #{ foreign_content_at_file.filename }"
                  # next  if foreign_content_at_file has no subtitles
                  if !foreign_content_at_file.has_subtitle_marks?
                    puts "         skipping, has no subtitle marks"
                    next
                  end
                  # Determine strategy for transferring st_ops
                  transfer_strategy = determine_st_ops_transfer_strategy(
                    foreign_content_at_file: foreign_content_at_file,
                    from_git_commit: @from_git_commit,
                    from_subtitles_count: from_subtitles_count,
                    st_ops_count_delta: st_ops_count_delta,
                    to_subtitles_count: to_subtitles_count,
                  )
                  case transfer_strategy
                  when :apply_st_ops_as_is_initial, :apply_st_ops_as_is_subsequent
                    apply_st_ops_as_is!(
                      st_ops_for_file,
                      from_subtitles,
                      to_subtitles,
                      foreign_content_at_file,
                      st_review_flags
                    )
                  when :review_manually
                    files_flagged_for_manual_review << foreign_content_at_file
                  when :resolve_mismatch_in_subtitle_counts
                    flag_file_for_manual_review(foreign_content_at_file)
                    files_flagged_for_manual_review << foreign_content_at_file
                  when :resolve_mismatch_in_git_commits
                    flag_file_for_manual_review(foreign_content_at_file)
                    files_flagged_for_manual_review << foreign_content_at_file
                  else
                    raise "Handle this: #{ transfer_strategy.inspect }"
                  end
                end
                finalize_foreign_repo_st_ops_transfer!(foreign_repo)
              end
            end
            finalize_global_st_ops_transfer(files_flagged_for_manual_review)
          end

        private

          # Determines the strategy for transferring subtitle ops
          # @param attrs [Hash]
          # @option attrs [RFile::ContentAt] foreign_content_at_file
          # @option attrs [String] from_git_commit
          # @option attrs [Integer] from_subtitles_count count of subtitles in primary file as of from_git_commit
          # @option attrs [Integer] st_ops_count_delta how number of subtitles changed when apply st_ops
          # @option attrs [Integer] to_subtitles_count count of subtitles in primary file as of to_git_commit
          # @return [Symbol]
          def determine_st_ops_transfer_strategy(attrs)
            fcaf = attrs[:foreign_content_at_file]
            if fcaf.read_file_level_data['subtitles_sync_requires_manual_review']
              return :review_manually
            end
            foreign_sts_lsagc = fcaf.read_file_level_data['subtitles_last_synched_at_git_commit']
            if foreign_sts_lsagc.nil?
              # Never been synced before, determine initial strategy
              determine_initial_transfer_strategy(attrs)
            else
              # Has been synched before, determine subsequent strategy
              determine_subsequent_transfer_strategy(
                attrs.merge(foreign_repo_last_synced_at_gc: foreign_sts_lsagc)
              )
            end
          end

          # @param attrs [Hash] see #determine_st_ops_transfer_strategy
          # @return [Symbol]
          def determine_initial_transfer_strategy(attrs)
            subtitle_marks_count_in_foreign_content_at_file = attrs[:foreign_content_at_file].contents.count('@')
            if(
              subtitle_marks_count_in_foreign_content_at_file == attrs[:from_subtitles_count] &&
              (attrs[:from_subtitles_count] + attrs[:st_ops_count_delta]) == attrs[:to_subtitles_count]
            )
              # foreign_content_at_file subtitle marks count is same as
              # from_subtitles_count.
              # That means we can just apply the ops.
              :apply_st_ops_as_is_initial
            else
              puts "mismatch in subtitle counts:"
              p attrs
              :resolve_mismatch_in_subtitle_counts
            end
          end

          # @param attrs [Hash] see #determine_st_ops_transfer_strategy
          # @return [Symbol]
          def determine_subsequent_transfer_strategy(attrs)
            if attrs[:foreign_repo_last_synced_at_gc] == attrs[:from_git_commit]
              :apply_st_ops_as_is_subsequent
            else
              puts "mismatch in git commits:"
              p attrs
              :resolve_mismatch_in_git_commits
            end
          end

          # Finalizes transfer of st ops to repo. Records which git_commit
          # repo was synced to.
          # @param repo [Repository]
          def finalize_foreign_repo_st_ops_transfer!(repo)
            # TODO: write to_git_commit to repo's data.json file under the
            # 'subtitles_last_synched_at_git_commit' key
          end

          # @param files_flagged_for_manual_review [Array<RFile::ContentAt]
          def finalize_global_st_ops_transfer(files_flagged_for_manual_review)
            puts "The following files require manual review:".color(:red)
            files_flagged_for_manual_review.each { |content_at_file|
              puts " - #{ content_at_file.filename }".color(:red)
            }
          end

          # Applies st_ops_for_file to foreign_content_at_file.
          # Returns ??? contents as string? makes changes in place?
          # @param st_ops_for_file [Subtitle::OperationsForFile]
          # @param from_subtitles [Array<Subtitle>]
          # @param to_subtitles [Array<Subtitle>]
          # @param foreign_content_at_file [RFile::ContentAt]
          # @param st_review_flags [Hash] { '<stid>' => <st_op.to_hash>, ... }
          def apply_st_ops_as_is!(st_ops_for_file, from_subtitles, to_subtitles, foreign_content_at_file, st_review_flags)
            new_foreign_content_at_contents = st_ops_for_file.apply_to_foreign_content_at_file(
              from_subtitles,
              to_subtitles,
              foreign_content_at_file
            )
            foreign_content_at_file.update_contents!(new_foreign_content_at_contents)
            # Flag subtitles for review
            existing_data = foreign_content_at_file.read_file_level_data
            already_flagged_sts = existing_data['subtitles_to_review'] || {}
            new_flagged_sts = already_flagged_sts.merge(st_review_flags)
            foreign_content_at_file.update_file_level_data(
              existing_data.merge('subtitles_to_review' => new_flagged_sts)
            )
          end

        end
      end
    end
  end
end
