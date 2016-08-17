# encoding UTF-8
class Repositext
  class Process
    class Sync
      class Subtitles
        module TransferSubtitleOperationsToForeignRepos

          extend ActiveSupport::Concern

          # @param st_ops_for_repo [Subtitle::OperationsForRepo]
          def transfer_subtitle_operations_to_foreign_repos!(st_ops_for_repo)
            puts " - Transferring subtitle operations to foreign repos".color(:blue)
            # Iterate over all files that have subtitle changes
            primary_files_flagged_for_manual_resolution = []
            st_ops_for_repo.operations_for_files.each do |st_ops_for_file|
              transfer_subtitle_operations_for_primary_file!(
                st_ops_for_file,
                primary_files_flagged_for_manual_resolution
              )
            end
            report_primary_files_flagged_for_manual_resolution(primary_files_flagged_for_manual_resolution)
            true
          end

        private

          # Takes a set of st_ops for a primary file and transfers them to all
          # applicable corresponding foreign files.
          # @param st_ops_for_file [Subtitle::OperationsForFile]
          # @param primary_files_flagged_for_manual_resolution [Array] collector for
          #        primary files that have subtitles which require manual resolution.
          # @param foreign_content_at_file_override [RFile::ContentAt, optional]
          #        use this if you call this method to transfer accumulated st
          #        ops for a single foreign file only.
          def transfer_subtitle_operations_for_primary_file!(
            st_ops_for_file,
            primary_files_flagged_for_manual_resolution,
            foreign_content_at_file_override=nil
          )
            verbose_logging = true
            # Compute all data related to the to_primary_content_at_file
            to_primary_content_at_file = st_ops_for_file.content_at_file
            primary_content_type = to_primary_content_at_file.content_type
            puts "   - primary file: #{ to_primary_content_at_file.basename }"
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

            # Iterate over all foreign repositories or just the override
            foreign_repos = if foreign_content_at_file_override
              # Use override
              [foreign_content_at_file_override.repository]
            else
              # Use all foreign content repos
              RepositorySet.new(@repository.parent_dir).all_repos(:foreign_content_repos)
            end
            foreign_repos.each do |foreign_repo|
              if !foreign_repo.read_repo_level_data['st_sync_active']
                # puts("     - #{ foreign_repo.name }: skip repository")  if verbose_logging
                next
              end
              foreign_files_flagged_for_manual_resolution = []
              print "     - #{ foreign_repo.name }: "

              # Compute foreign content_type
              foreign_content_type = if foreign_content_at_file_override
                # Use content_type from file override
                foreign_content_at_file_override.content_type
              else
                # Use primary's corresponding foreign content type
                primary_content_type.corresponding_content_type_in_other_repo(foreign_repo)
              end

              # find corresponding foreign content_at file
              foreign_content_at_file = (
                foreign_content_at_file_override ||
                RFile::ContentAt.find_by_product_identity_id(
                  to_primary_content_at_file.extract_product_identity_id,
                  foreign_content_type
                )
              )

              # Skip file under a number of conditions
              if foreign_content_at_file.nil?
                puts(verbose_logging ? "skip, corresponding file does not exist" : '')
                next
              end
              if foreign_content_at_file.read_file_level_data['exported_subtitles_at_st_sync_commit']
                puts(verbose_logging ? "skip, has pending subtitle import" : '')
                next
              end
              if foreign_content_at_file.read_file_level_data['st_sync_commit'] == @to_git_commit
                puts(verbose_logging ? "skip, subtitles are already synced" : '')
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
              when :apply_initial_custom_st_ops
                # First sync to foreign file, file already contains subtitles.
                # Determine what version of primary subtitles are based on
                # and sync from there.
                print "apply initial custom st-ops"
                # TBD
                puts " - TBD".color(:yellow)
              when :apply_subsequent_st_ops_as_is
                # Subsequent sync to foreign file. All versions match, apply
                # st-ops as is.
                print " apply subsequent st-ops as is"
                apply_st_ops_as_is!(
                  st_ops_for_file,
                  from_subtitles,
                  to_subtitles,
                  foreign_content_at_file,
                  st_review_flags
                )
                puts " - OK".color(:green)
              when :auto_split_initial_subtitles
                # First sync to foreign file. File contains no subtitles,
                # so we auto split subtitles based on current primary and
                # flag file for review.
                print "auto split initial subtitles"
                # TBD
                puts " - TBD".color(:yellow)
              when :resolve_inconsistent_git_history
                puts "resolve inconsistent git history"
                foreign_files_flagged_for_manual_resolution << foreign_content_at_file
                primary_files_flagged_for_manual_resolution << to_primary_content_at_file
              when :resolve_manually
                puts "resolve manually"
                foreign_files_flagged_for_manual_resolution << foreign_content_at_file
                primary_files_flagged_for_manual_resolution << to_primary_content_at_file
              else
                raise "Handle this: #{ transfer_strategy.inspect }"
              end

              # We don't want to finalize the repo if we just transferred
              # st ops for a single file via override...
              if !foreign_content_at_file_override
                finalize_foreign_repo_st_ops_transfer!(
                  foreign_repo,
                  foreign_files_flagged_for_manual_resolution
                )
              end
            end
            true
          end

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
            if fcaf.read_file_level_data['st_sync_file_requires_manual_resolution']
              return :resolve_manually
            end
            foreign_stsc = fcaf.read_file_level_data['st_sync_commit']
            if foreign_stsc.nil?
              # Never been synced before, determine initial strategy
              determine_initial_transfer_strategy(attrs)
            else
              # Has been synched before, determine subsequent strategy
              determine_subsequent_transfer_strategy(
                attrs.merge(foreign_repo_last_synced_at_gc: foreign_stsc)
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
          # @param foreign_repo [Repository]
          # @param files_flagged_for_manual_resolution [Array] list of files to be flagged
          def finalize_foreign_repo_st_ops_transfer!(foreign_repo, files_flagged_for_manual_resolution)
            # NOTE: We don't write st_sync_commit at the foreign repo level.
            # We track it at the file level instead.

            # Handle any foreign files that are flagged for manual resolution
            fffmr = files_flagged_for_manual_resolution.uniq { |e|
              e.filename
            }
            if fffmr.any?
              puts "The following foreign files require manual resolution:".color(:red)
              fffmr.each { |content_at_file|
                puts " - #{ content_at_file.filename }".color(:red)
                content_at_file.update_file_level_data(
                  'st_sync_file_requires_manual_resolution' => true
                )
              }
            end
          end

          # @param files_flagged_for_manual_resolution [Array<RFile::ContentAt]
          #     List of files in primary repo that require review. May contain
          #     duplicates.
          def report_primary_files_flagged_for_manual_resolution(files_flagged_for_manual_resolution)
            return true  if files_flagged_for_manual_resolution.empty?
            puts "The following primary files have corresponding foreign files that require manual resolution:".color(:red)
            files_flagged_for_manual_resolution.uniq { |e|
              e.filename
            }.each { |content_at_file|
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
            already_flagged_sts = existing_data['st_sync_subtitles_to_review'] || {}
            new_flagged_sts = already_flagged_sts.merge(st_review_flags)
            foreign_content_at_file.update_file_level_data(
              existing_data.merge({
                'st_sync_commit' => st_ops_for_file.to_git_commit,
                'st_sync_subtitles_to_review' => new_flagged_sts,
              })
            )
          end

        end
      end
    end
  end
end
