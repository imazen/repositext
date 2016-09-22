class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        module AlignSubtitlePairs

          # Aligns subtitle pairs.
          # @param sts_from [Array<SubtitleAttrs>]
          # @param sts_to [Array<SubtitleAttrs>]
          # @return [Array<AlignedSubtitlePair>]
          def align_subtitle_pairs(sts_from, sts_to)
            asps = compute_aligned_subtitle_pairs(sts_from, sts_to)
            enriched_asps = enrich_aligned_subtitle_pair_attributes(asps)
            post_processed_asps = post_process_aligned_subtitle_pairs!(enriched_asps)
          end

        private

          # @param sts_from [Array<SubtitleAttrs>]
          # @param sts_to [Array<SubtitleAttrs>]
          # @return [Array<AlignedSubtitlePair>]
          def compute_aligned_subtitle_pairs(sts_from, sts_to)
            st_count_from = sts_from.inject(0) { |m,e| m += e[:subtitle_count] }
            st_count_to = sts_to.inject(0) { |m,e| m += e[:subtitle_count] }
            total_subtitle_count_change = st_count_to - st_count_from
            diagonal_band_range = [
              (total_subtitle_count_change.abs * 1.2).round,
              25
            ].max

            aligner = SubtitleAligner.new(
              sts_from,
              sts_to,
              { diagonal_band_range: diagonal_band_range }
            )
            print " with diagonal_band_range #{ diagonal_band_range }"
            aligned_subtitles_from, aligned_subtitles_to = aligner.get_optimal_alignment

            # check for max alignment offset
            max_alignment_offset = 0
            prev_st_index_from = 0
            prev_st_index_to = 0
            r = aligned_subtitles_from.map { |st_from|
              st_to = aligned_subtitles_to.shift
              prev_st_index_from = (st_from[:index] ||= prev_st_index_from)
              prev_st_index_to = (st_to[:index] ||= prev_st_index_to)
              alignment_offset = (st_to[:index] - st_from[:index]).abs
              max_alignment_offset = [max_alignment_offset, alignment_offset].max
              {
                from: st_from,
                to: st_to
              }
            }

            if max_alignment_offset >= diagonal_band_range
              raise "Diagonal_band_range too narrow for max offset of #{ max_alignment_offset }"
            end
            r
          end

          # @param aligned_subtitle_pairs [Array<AlignedSubtitlePair>]
          # @return [Array<AlignedSubtitlePair>]
          def enrich_aligned_subtitle_pair_attributes(aligned_subtitle_pairs)
            enriched_aligned_subtitle_pairs = []
            most_recent_existing_subtitle_id = nil # to create temp subtitle ids
            temp_subtitle_offset = 0
            # Compute truncation length for sim_left and sim_right. We only
            # consider the first/last 30 chars. This length is aligned with
            # max_conf_at_char_length in `StringComputations.similarity`.
            half_truncation_length = 30

            aligned_subtitle_pairs.each_with_index { |asp,idx|
              # Assign Subtitle object
              st_obj = if '' == asp[:from][:content]
                # Subtitle doesn't exist in `from` content, create temp subtitle object
                ::Repositext::Subtitle.new(
                  persistent_id: [
                    'tmp-',
                    most_recent_existing_subtitle_id || 'new_file',
                    '+',
                    temp_subtitle_offset += 1,
                  ].join,
                  tmp_attrs: {}
                )
              else
                # Subtitle id exists in `from` content, use it
                most_recent_existing_subtitle_id = asp[:from][:persistent_id]
                ::Repositext::Subtitle.new(
                  persistent_id: asp[:from][:persistent_id],
                  record_id: asp[:from][:record_id],
                  tmp_attrs: {}
                )
              end
              st_obj.tmp_attrs[:before] = asp[:from][:content]
              st_obj.tmp_attrs[:after] = asp[:to][:content]
              asp[:subtitle_object] = st_obj

              # Compute various similarities between deleted and added content
              sim_text_from = asp[:from][:content_sim]
              sim_text_to = asp[:to][:content_sim]
              asp[:sim_left] = StringComputations.similarity(
                sim_text_from,
                sim_text_to,
                half_truncation_length,
                :left
              )
              asp[:sim_right] = StringComputations.similarity(
                sim_text_from,
                sim_text_to,
                half_truncation_length,
                :right
              )
              asp[:sim_abs] = StringComputations.similarity(
                sim_text_from,
                sim_text_to,
                false # look at all chars, don't truncate
              )

              # Compute remaining attrs
              asp[:content_length_change] = (
                asp[:to][:content].strip.length - asp[:from][:content].strip.length
              ) # neg means text removal
              asp[:subtitle_count_change] = compute_subtitle_count_change(asp)
              asp[:has_repetitions] = compute_repetitions(
                asp[:from][:repetitions],
                asp[:to][:repetitions]
              )
              asp[:index] = idx + 1 # one based subtitle index
              # Take first and last_in_para from `to` st
              asp[:first_in_para] = asp[:to][:first_in_para]
              asp[:last_in_para] = asp[:to][:last_in_para]

              asp[:type] = compute_subtitle_pair_type(asp)
              enriched_aligned_subtitle_pairs << asp
            }
            enriched_aligned_subtitle_pairs
          end

          # Post processes aligned_subtitle_pairs:
          # * Fixes alignment type issues around subtitles with repeated phrases
          # * Assign missing record_ids
          # Modifies asps in place.
          # @param asps [Array<AlignedSubtitlePair>]
          # @return [Array<AlignedSubtitlePair>]
          def post_process_aligned_subtitle_pairs!(asps)
            asps.each_with_index do |cur, idx|
              prev_b1 = idx > 1 ? asps[idx-2] : nil
              prev = idx > 0 ? asps[idx-1] : nil
              nxt = idx < (asps.length-1) ? asps[idx+1] : nil
              nxt_bo = idx < (asps.length-2) ? asps[idx+2] : nil
              nxt_b2 = idx < (asps.length-3) ? asps[idx+3] : nil
              nxt_b3 = idx < (asps.length-4) ? asps[idx+4] : nil

              fix_alignment_issues_around_subtitles_with_repeated_phrases!(
                cur,
                nxt
              )
              update_record_ids!(
                prev_b1,
                prev,
                cur,
                nxt,
                nxt_bo,
                nxt_b2,
                nxt_b3
              )
            end

            asps
          end

          # If a subtitle pair has type "right_aligned" and is followed by
          # an ins/del, we change it to "unaligned" if it has repetitions
          # and text overlap with the following ST.
          # This method modifies `cur` in place to fix the issue.
          # @param cur [AlignedSubtitlePair]
          # @param nxt [AlignedSubtitlePair]
          def fix_alignment_issues_around_subtitles_with_repeated_phrases!(cur, nxt)
            return true  if nxt.nil? # We're at the last ASP, nothing to do.
            if(
              cur[:has_repetitions] &&
              :right_aligned == cur[:type] &&
              [:st_added, :st_removed].include?(nxt[:type]) &&
              (
                StringComputations.overlap(
                  cur[:to][:content_sim],
                  nxt[:from][:content_sim]
                ) > 0 ||
                StringComputations.overlap(
                  cur[:from][:content_sim],
                  nxt[:to][:content_sim]
                ) > 0
              )
            )
              # Change type to `unaligned`
              cur[:type] = :unaligned
            end
          end

          # Updates cur[:subtitle_object]'s record_id:
          #   * Assigns record_ids to newly inserted subtitles.
          #   * Updates record_ids of existing subtitles that moved to a
          #     different record.
          # Modifies `cur`s [:subtitle_object] in place.
          # @param prev_b1 [AlignedSubtitlePair]
          # @param prev [AlignedSubtitlePair]
          # @param cur [AlignedSubtitlePair]
          # @param nxt [AlignedSubtitlePair]
          # @param nxt_bo [AlignedSubtitlePair]
          # @param nxt_b2 [AlignedSubtitlePair]
          # @param nxt_b3 [AlignedSubtitlePair]
          def update_record_ids!(prev_b1, prev, cur, nxt, nxt_bo, nxt_b2, nxt_b3)
            # First insert missing record_ids. Look one asp back and four ahead
            if cur[:subtitle_object].record_id.nil?
              assign_missing_record_id!(prev, cur, nxt, nxt_bo, nxt_b2, nxt_b3)
            end
            # Then adjust record_ids on subtitles that moved to different record.
            # We can't look ahead since next ones still may be nil. This step
            # does not handle nil record_ids.
            # So we operate on `prev` and use `prev_b1` as preceding and `cur` as following.
            if(
              (
                prev_b1 &&
                prev[:subtitle_object].record_id != prev_b1[:subtitle_object].record_id &&
                prev[:to][:para_index] == prev_b1[:to][:para_index]
              ) || (
                prev &&
                prev[:subtitle_object].record_id != cur[:subtitle_object].record_id &&
                prev[:to][:para_index] == cur[:to][:para_index]
              )
            )
              # Two STs in same para have different record_ids.
              adjust_misaligned_record_id!(prev_b1, prev, cur)
            end
          end

          # Given cur with nil [:subtitle_object].record_id, assigns a new record_id.
          # Modifies `cur` in place.
          # @param prev [AlignedSubtitlePair]
          # @param cur [AlignedSubtitlePair]
          # @param nxt [AlignedSubtitlePair]
          # @param nxt_bo [AlignedSubtitlePair]
          # @param nxt_b2 [AlignedSubtitlePair]
          # @param nxt_b3 [AlignedSubtitlePair]
          def assign_missing_record_id!(prev, cur, nxt, nxt_bo, nxt_b2, nxt_b3)
            preceding_record_id = prev.nil? ? nil : prev[:subtitle_object].record_id
            following_record_id = [nxt, nxt_bo, nxt_b2, nxt_b3].map { |asp|
              next nil  if asp.nil?
              asp[:from] && asp[:from][:record_id]
            }.compact.first

            new_record_id = if prev.nil? && following_record_id
              # We're at the first ASP
              following_record_id
            elsif nxt.nil? && preceding_record_id
              # We're at the last ASP
              preceding_record_id
            elsif((preceding_record_id == following_record_id) && preceding_record_id)
              # group sequence of nil record_ids between STs with identical
              # record_ids, use from prev
              preceding_record_id
            elsif((prev[:to][:para_index] == cur[:to][:para_index]) && preceding_record_id)
              # cur is located in same paragraph as prev
              preceding_record_id
            elsif((nxt[:to][:para_index] == cur[:to][:para_index]) && following_record_id)
              # cur is located in same paragraph as nxt
              following_record_id
            elsif prev[:to][:para_index] == (nxt[:to][:para_index] - 2)
              # cur is different from both. We use the first existing one from
              # prev and nxt
              preceding_record_id || following_record_id
            else
              raise "Handle this: #{ [prev, cur, nxt, nxt_bo, nxt_b2, nxt_b3].inspect }"
            end

            if new_record_id.nil?
              raise "Assigned nil record id at #{ [prev, cur, nxt, nxt_bo, nxt_b2, nxt_b3].inspect }"
            end

            cur[:subtitle_object].record_id = new_record_id
          end

          # Adjusts record_ids for subtitles that moved to a different record.
          # We can safely assume that none of prev_b1, prev, or cur's
          # [:subtitle_object].record_id is nil,
          # and that it is different from either prev_b1 or cur's.
          # Modifies `prev` in place.
          # @param prev_b1 [AlignedSubtitlePair]
          # @param prev [AlignedSubtitlePair]
          # @param cur [AlignedSubtitlePair]
          def adjust_misaligned_record_id!(prev_b1, prev, cur)
            new_record_id = if prev_b1[:to][:para_index] == prev[:to][:para_index]
              # Use record_id from prev_b1
              prev_b1[:subtitle_object].record_id
            elsif cur[:to][:para_index] == prev[:to][:para_index]
              # use record_id from cur
              cur[:subtitle_object].record_id
            else
              raise "Handle this: #{ [prev_b1, prev, cur].inspect }"
            end
            prev[:subtitle_object].record_id = new_record_id
          end

          # Returns difference in subtitles from :from to :to in al_st_pair.
          # @param al_st_pair [AlignedSubtitlePair]
          # @return [Integer]
          def compute_subtitle_count_change(al_st_pair)
            (
              al_st_pair[:to][:subtitle_count]
            ) - (
              al_st_pair[:from][:subtitle_count]
            )
          end

          # Returns nature of al_st_pair.
          # @param al_st_pair [AlignedSubtitlePair]
          # @return [Symbol]
          def compute_subtitle_pair_type(al_st_pair)
            # check for gap first, so that we can assume presence of content in later checks.
            if 1 == al_st_pair[:subtitle_count_change]
              # Subtitle was added
              :st_added
            elsif -1 == al_st_pair[:subtitle_count_change]
              # Subtitle was removed
              :st_removed
            else
              # No ins/del, compute alignment
              high_sim_left = (
                al_st_pair[:sim_left].first >= 0.87 and
                al_st_pair[:sim_left].last >= 0.9
              ) ? al_st_pair[:sim_left].first : false
              high_sim_right = (
                al_st_pair[:sim_right].first >= 0.87 and
                al_st_pair[:sim_right].last >= 0.9
              ) ? al_st_pair[:sim_right].first : false
              has_repetitions = al_st_pair[:has_repetitions]
              if(
                al_st_pair[:sim_abs].first > 0.93 and al_st_pair[:sim_abs].last == 1.0 and
                high_sim_left and
                high_sim_right
              )
                # very high absolute similarity, sufficient confidence
                :fully_aligned
              elsif high_sim_left && high_sim_right
                # Both similarities score high, use max to determine alignment
                high_sim_left >= high_sim_right ? :left_aligned : :right_aligned
              elsif high_sim_left
                # very high left similarity, sufficient confidence
                :left_aligned
              elsif high_sim_right
                # very high right similarity, sufficient confidence
                :right_aligned
              else
                :unaligned
              end
            end
          end

          # @param reps_from [Hash] {"repeated_text"=>[0, 23, 41, 60]}
          # @param reps_to [Hash]
          def compute_repetitions(reps_from, reps_to)
            [reps_from, reps_to].any? { |reps| reps.any? { |k,v| v.length > 1 } }
          end

        end
      end
    end
  end
end
