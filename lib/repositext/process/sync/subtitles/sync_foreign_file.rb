class Repositext
  class Process
    class Sync
      class Subtitles
        # This namespace provides methods related to syncing subtitles for a foreign file.
        module SyncForeignFile

          extend ActiveSupport::Concern

          include ComputeApplicableStOpsForForeignFile
          include TransferApplicableStOpsToForeignFile

          # Syncronizes subtitle operations for the foreign_content_at_file
          # @param f_content_at_file [RFile::ContentAt]
          # @return [Boolean] true if successful, false if not.
          # side_effects: appends to @successful_files or @unprocessable_files.
          def sync_foreign_file(f_content_at_file)
            print "   - #{ f_content_at_file.repo_relative_path }: ".ljust(50)

            # Find from_git_commit
            fgc_o = Process::Compute::StSyncFromGitCommitForForeignFile.new(
              f_content_at_file,
              @earliest_from_git_commit,
              @config
            ).compute

            if fgc_o.success?
              # We found a from_git_commit, either from file data, or from
              # subitle_export's commit date.
              process_with_from_git_commit(
                f_content_at_file,
                fgc_o.result[:from_git_commit],
                fgc_o.result[:source]
              )
            elsif :autosplit == fgc_o.result[:source]
              # This file requires autosplit. After autosplit, file will be
              # synced to primary repo's current @to_git_commit.
              @auto_split_files_collector[f_content_at_file.language_code_3_chars] << f_content_at_file.extract_date_code
              process_autosplit(f_content_at_file, @to_git_commit)
            else
              # This file can't be processed
              process_unprocessable(f_content_at_file, fgc_o.messages.join(' '))
            end
          end

          # @param f_content_at_file [RFile::ContentAt] the foreign content AT file.
          # @param file_from_git_commit [String] the full commit SHA1 string.
          # @param ffgc_source [Symbol] one of :file_level_data or :subtitle_export.
          # @return [Boolean] true if successful, false if not
          def process_with_from_git_commit(f_content_at_file, file_from_git_commit, ffgc_source)
            print "     - from_git_commit: #{ file_from_git_commit.inspect }, source: #{ ffgc_source.inspect }"

            # Find applicable st_ops
            aso_o = compute_applicable_st_ops_for_foreign_file(
              f_content_at_file,
              file_from_git_commit,
              ffgc_source
            )
            if !aso_o.success?
              msg = aso_o.messages.join(' ')
              @unprocessable_files << {
                file: f_content_at_file,
                message: msg,
              }
              puts # terminate log line
              puts msg.color(:red)
              return false
            end
            applicable_st_ops = aso_o.result

            # Transfer applicable st_ops
            transfer_applicable_st_ops_to_foreign_file!(
              f_content_at_file,
              applicable_st_ops
            )
            if applicable_st_ops.any?
              @successful_files_with_st_ops << f_content_at_file.repo_relative_path(true)
            else
              @successful_files_without_st_ops << f_content_at_file.repo_relative_path(true)
            end
            puts # terminate log line
            true
          end

          # @param f_content_at_file [RFile::ContentAt] the foreign content AT file.
          # @param st_sync_commit [String] the full commit SHA1 string.
          #   Will be used as file's st_sync_commit.
          def process_autosplit(f_content_at_file, st_sync_commit)
            puts "     - source: :autosplit"

            # We don't want an error in autosplit to stop the sync process
            # so we rescue exceptions.
            begin
              # Autosplit subtitles
              ss_o = Process::Split::Subtitles.new(
                f_content_at_file.corresponding_primary_file,
                f_content_at_file
              ).split

              if ss_o.success?
                new_content_at, _st_confidences = ss_o.result

                # Update foreign content AT file with new subtitles
                f_content_at_file.update_contents!(new_content_at)


                # Update foreign st_sync related data
                f_content_at_file.update_file_level_data!(
                  'st_sync_commit' => st_sync_commit,
                  'st_sync_subtitles_to_review' => { 'all' => ['autosplit'] },
                )

                @successful_files_with_autosplit << f_content_at_file.repo_relative_path(true)
                puts # terminate log line
                true
              else
                process_unprocessable(f_content_at_file, ss_o.messages.join(' '))
              end
            rescue StandardError => e
              # Capture the file with exception
              @files_with_autosplit_exceptions << {
                file: f_content_at_file,
                message: e.message,
              }
              # Print error to console
              puts "   - Error: #{ e.message }".color(:red)
            end

          end

          # @param f_content_at_file [RFile::ContentAt] the foreign content AT file.
          # @param error_message [String]
          # @return [False]
          def process_unprocessable(f_content_at_file, error_message)
            @unprocessable_files << {
              file: f_content_at_file,
              message: error_message
            }

            puts # terminate log line
            puts error_message.color(:red)
            false
          end
        end
      end
    end
  end
end
