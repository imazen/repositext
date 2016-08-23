class Repositext
  class Process
    class Sync
      class Subtitles
        module SyncPrimaryFile

          extend ActiveSupport::Concern

          # Syncronizes subtitle operations in the primary file
          # @param content_at_file_current [RFile::ContentAt] current version of file
          # @param st_ops_for_repo [Repositext::Subtitle::OperationsForRepository]
          def sync_primary_file(content_at_file, st_ops_for_repo)
            puts "     - process #{ content_at_file.repo_relative_path }"
            st_ops_for_file = extract_st_ops_for_primary_file(
              content_at_file.extract_product_identity_id,
              st_ops_for_repo
            )
            update_primary_subtitle_marker_csv_file(
              content_at_file,
              st_ops_for_file
            )
            update_primary_file_level_st_sync_data(content_at_file)
          end

        private

          # Updates STM CSV file for content_at_file_current.
          # Computes new STM CSV file data by merging the following:
          #  * Existing STIDS and record ids from existing STM CSV file.
          #  * New time slices from subtitle import marker file.
          #  * Updated subtitles based on subtitle operations (with new stids)
          # Then updates the STM CSV file with the new data.
          # @param content_at_file [RFile::ContentAt]
          # @param st_ops_for_file [Subtitle::OperationsForFile]
          # @return [True]
          def update_primary_subtitle_marker_csv_file(content_at_file_current, st_ops_for_file)
            # Get content_at_file as of from_git_commit
            content_at_file = content_at_file_current.as_of_git_commit(@from_git_commit)
            csv_file = content_at_file.corresponding_subtitle_markers_csv_file
            old_stids, new_time_slices = extract_primary_stm_csv_file_input_data(
              content_at_file,
              st_ops_for_file
            )

            new_char_lengths = compute_new_char_lengths(content_at_file)

            validate_subtitle_sync_input_data(
              content_at_file,
              old_stids,
              new_time_slices,
              st_ops_for_file
            )
            new_subtitles_data = compute_new_subtitle_data(
              old_stids,
              new_time_slices,
              new_char_lengths,
              st_ops_for_file
            )
            update_stm_csv_file(
              content_at_file.corresponding_subtitle_markers_csv_file,
              new_subtitles_data
            )

            true
          end

          # @param content_at_file [RFile::ContentAt]
          def update_primary_file_level_st_sync_data(content_at_file)
            content_at_file.update_file_level_data(
              'st_sync_required' => false,
              'last_st_sync_commit_for_this_file' => @to_git_commit,
            )
          end

          # @param st_ops_for_repo [Repositext::Subtitle::OperationsForRepository]
          # @return [Subtitle::OperationsForFile, Nil]
          def extract_st_ops_for_primary_file(product_identity_id, st_ops_for_repo)
            st_ops_for_repo.operations_for_files.detect { |e|
              product_identity_id == e.product_identity_id
            }
          end

          # Extracts old_stids and new_time_slices for content_at_file.
          # Returns empty arrays if no st_ops exist for file.
          # @param content_at_file [RFile::ContentAt]
          # @param st_ops_for_file [Subtitle::OperationsForFile]
          # @return [Array] with the following elements:
          #     * old_stids <Array>
          #     * new_time_slices <Array>
          def extract_primary_stm_csv_file_input_data(content_at_file, st_ops_for_file)
            # Return blank values if no st_ops are found for file
            return [[],[]]  if st_ops_for_file.nil?

            # old_stids: extract STIDs and record_ids from corresponding STM CSV file
            old_stids = []
            corr_stm_csv_file = content_at_file.corresponding_subtitle_markers_csv_file
                                               .as_of_git_commit(@from_git_commit)
            corr_stm_csv_file.each_row { |e|
              old_stids << { persistent_id: e['persistentId'], record_id: e['recordId'] }
            }

            # new_time_slices: extract time_slices from corresponding_subtitle_import_markers_file
            new_time_slices = []
            corr_st_import_markers_file = content_at_file.corresponding_subtitle_import_markers_file
            if corr_st_import_markers_file.nil?
              # No corresponding subtitle import markers file exists.
              # This is unexpected since we ran Fix::PrepareInitialPrimarySubtitleSync
              # which would have created a subtitle_import file for every
              # primary content AT file.
              raise "no subtitle import file for #{ content_at_file.filename }"
            else
              # Import file exists, grab updated time slices from there
              corr_st_import_markers_file.each_row { |e|
                new_time_slices << { relative_milliseconds: e['relativeMS'], samples: e['samples'] }
              }
            end

            [old_stids, new_time_slices]
          end

          # Computes new subtitle char_lengths for all subtitles in content_at.
          # @param content_at_file [RFile::ContentAt] needs to be at toGitCommit
          # @return [Array<Integer>]
          def compute_new_char_lengths(content_at_file)
            Repositext::Utils::SubtitleMarkTools.extract_captions(
              content_at_file.contents
            ).map { |e| e[:char_length] }
          end

          # Raises an exception if any of the input data is not valid
          # @param content_at_file [RFile::ContentAt]
          # @param old_stids [Array<Hash>]
          # @param new_time_slices [Array<Hash>]
          # @param st_ops_for_file [Subtitle::OperationsForFile]
          def validate_subtitle_sync_input_data(content_at_file, old_stids, new_time_slices, st_ops_for_file)
            # Validate that old and new subtitle counts are consistent with operations
            st_ops_count_delta = st_ops_for_file.subtitles_count_delta
            if old_stids.length + st_ops_count_delta != new_time_slices.length
              raise InvalidInputDataError.new(
                [
                  "Subtitle count mismatch:",
                  "existing STM CSV file contains #{ old_stids.length } subtitles,",
                  "subtitle ops changed count by #{ st_ops_count_delta }",
                  "new subtitle import files contain #{ new_time_slices.length } subtitles",
                  "for file #{ content_at_file.filename }",
                ].join(' ')
              )
            end
          end

          # Returns updated subtitles data
          # @param old_sts [Array<Hash>]
          # @param new_time_slices [Array<Hash>]
          # @param new_char_lengths [Array<Integer>] mapped to new_time_slices
          # @param st_ops_for_file [Subtitle::OperationsForFile]
          # @return [Array<Hash>] with one key for each STM CSV file column:
          #         [
          #           {
          #             relative_milliseconds: 123,
          #             samples: 123,
          #             char_length: 123,
          #             persistent_id: 123,
          #             record_id: 123,
          #           }
          #         ]
          def compute_new_subtitle_data(old_sts, new_time_slices, new_char_lengths, st_ops_for_file)
            new_sts = st_ops_for_file.apply_to_subtitles(old_sts)
            # Merge new time slices and char_lengths
            new_sts.each_with_index { |new_st, idx|
              new_st.merge!(new_time_slices[idx])
              new_st[:char_length] = new_char_lengths[idx]
            }
            # Assign record ids to inserted subtitles
            # Since every paragraph has to start with a subtitle, we can assume
            # that any added subtitles are after an existing subtitle.
            # TODO: move this out of this method, pass new_record_ids as argument to method.
            if new_sts.first[:record_id].nil?
              raise "Handle this: #{ new_sts.inspect }"
            end
            new_sts.each_cons(2) { |previous_st, st|
              if st[:record_id].nil?
                if previous_st[:record_id].nil?
                  raise "Handle this: #{ new_sts.inspect }"
                end
                st[:record_id] = previous_st[:record_id]
              end
            }
            new_sts
          end

          # Updates stm_csv_file with new_subtitles_data
          # @param stm_csv_file [RFile::SubtitleMarkersCsv]
          # @param new_subtitles_data []
          def update_stm_csv_file(stm_csv_file, new_subtitles_data)
            stm_csv_file.update!(new_subtitles_data)
          end
        end
      end
    end
  end
end
