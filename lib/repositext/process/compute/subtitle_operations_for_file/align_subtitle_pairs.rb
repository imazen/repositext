class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        # Namespace for methods related to aligning subtitle pairs.
        module AlignSubtitlePairs

          # Aligns subtitle pairs. Handles two scenarios:
          #  1. Initial sync: Subtitles that weren't aligned previously.
          #     In this scenario we look at subtitle content for alignment,
          #     and we have to perform various post processing steps.
          #  2. Recomputing st_ops: Subtitles that were aligned previously.
          #     In this scenario both `from` and `to` subtitles have stids.
          #     This allows for simpler alignment using stids, and eliminates
          #     the need for certain post-processing steps.
          # @param sts_from [Array<SubtitleAttrs>]
          # @param sts_to [Array<SubtitleAttrs>]
          # @return [Array<AlignedSubtitlePair>]
          def align_subtitle_pairs(sts_from, sts_to)
            alignment_strategy = compute_alignment_strategy(sts_to)
            asps = compute_aligned_subtitle_pairs(sts_from, sts_to, alignment_strategy)
            enriched_asps = enrich_aligned_subtitle_pair_attributes(asps)

            final_asps = case alignment_strategy
            when :use_contents
              post_process_aligned_subtitle_pairs!(enriched_asps)
            when :use_stids
              # no post processing required
              enriched_asps
            else
              raise "Handle this: #{ alignment_strategy.inspect }"
            end
          end

        private

          # Determines what approach to take for subtitle alignment.
          # @param sts_to [Array<SubtitleAttrs>]
          # @return [Symbol]
          def compute_alignment_strategy(sts_to)
            if sts_to.all? { |e| '' != e[:persistent_id].to_s.strip }
              # All `to` subtitles already have an stid, use it for alignment.
              :use_stids
            else
              # `To` subtitles don't have stids, have to use content for alignment.
              :use_contents
            end
          end

          # @param sts_from [Array<SubtitleAttrs>]
          # @param sts_to [Array<SubtitleAttrs>]
          # @param alignment_strategy [Symbol]
          # @return [Array<AlignedSubtitlePair>]
          def compute_aligned_subtitle_pairs(sts_from, sts_to, alignment_strategy)
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
              {
                alignment_strategy: alignment_strategy,
                diagonal_band_range: diagonal_band_range,
              }
            )

            print " with diagonal_band_range #{ diagonal_band_range }"
            aligned_subtitles_from, aligned_subtitles_to = aligner.get_optimal_alignment

            # check for max alignment offset
            max_alignment_offset = 0
            prev_st_index_from = 0
            prev_st_index_to = 0
            r = aligned_subtitles_from.map { |st_from|
              st_to = aligned_subtitles_to.shift
              # Fill in :index for gaps
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

          # Adds further attributes to aligned_subtitle_pairs:
          #  * subtitle object
          #  * before and after contents
          #  * similarity metrics
          #  * attribute flags
          # @param aligned_subtitle_pairs [Array<AlignedSubtitlePair>]
          # @return [Array<AlignedSubtitlePair>]
          def enrich_aligned_subtitle_pair_attributes(aligned_subtitle_pairs)
            enriched_aligned_subtitle_pairs = []
            most_recent_existing_subtitle_id = nil # to create temp subtitle ids
            temp_subtitle_offset = 0
            # Compute truncation length for sim_left and sim_right. We only
            # consider the first/last N chars. This length is aligned with
            # max_conf_at_char_length in `StringComputations.similarity`.
            half_truncation_length = 15

            aligned_subtitle_pairs.each_with_index { |asp,idx|
              st_index = idx + 1 # subtitle indexes are one-based
              # Assign Subtitle object
              st_obj = if '' == asp[:from][:content]
                # Subtitle doesn't exist in `from` content, create temp subtitle object
                p_id = if '' == asp[:to][:persistent_id].to_s.strip
                  # We're computing new st_ops, assign temporary stid
                  [
                    'tmp-',
                    most_recent_existing_subtitle_id || 'new_file',
                    '+',
                    temp_subtitle_offset += 1,
                  ].join
                else
                  # We're re-computing existing st_ops, use existing stid
                  asp[:to][:persistent_id]
                end
                ::Repositext::Subtitle.new(
                  persistent_id: p_id,
                  tmp_attrs: { index: st_index },
                  record_id: asp[:to][:record_id]
                )
              else
                # Subtitle id exists in `from` content, use it.
                # NOTE: We use record_id from `to`!
                most_recent_existing_subtitle_id = asp[:from][:persistent_id]
                ::Repositext::Subtitle.new(
                  persistent_id: most_recent_existing_subtitle_id,
                  record_id: asp[:to][:record_id],
                  tmp_attrs: { index: st_index },
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
              asp[:index] = st_index
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
              prev = idx > 0 ? asps[idx-1] : nil
              nxt = idx < (asps.length-1) ? asps[idx+1] : nil
              fix_alignment_issues_around_subtitles_with_repeated_phrases!(
                prev,
                cur,
                nxt
              )
            end

            asps
          end

          # This method fixes two issues around subtitle pairs that have repetitions:
          #
          # 1) If a subtitle pair has type :right_aligned and is followed by
          # an ins/del, we change it to :unaligned if it has repetitions
          # and text overlap with the following ASP.
          # 2) If a subtitle pair has repetitions, it will be marked as :unaligned,
          # even though it may be perfectly aligned. We fix that in this method.
          #
          # This method modifies `cur` in place to fix the issue.
          # @param prev [AlignedSubtitlePair]
          # @param cur [AlignedSubtitlePair]
          # @param nxt [AlignedSubtitlePair]
          def fix_alignment_issues_around_subtitles_with_repeated_phrases!(prev, cur, nxt)

            # Handle first issue
            if(
              cur[:has_repetitions] &&
              :right_aligned == cur[:type] &&
              nxt &&
              [:st_added, :st_removed].include?(nxt[:type]) &&
              asps_have_overlap(cur, nxt)
            )
              # Change type to :unaligned
              cur[:type] = :unaligned
            end

            # Handle second issue
            if !(:unaligned == cur[:type] && cur[:has_repetitions])
              # Irrelevant alignment or no repetitions, nothing to do.
              return true
            end

            # At this point we have an :unaligned ASP with repetitions.
            # We want to mark it as :left_aligned or :right_aligned if that
            # is the case.
            cur_repeated_phrases = [:from, :to].map { |e|
              cur[e][:repetitions].keys
            }.flatten
              .uniq
              .compact
              .map { |e| e.strip }
              .find_all { |e| '' != e }
            prev_reps_aligned, cur_reps_aligned, nxt_reps_aligned = [prev, cur, nxt].map { |asp|
              return true  if asp.nil?

              # Determine if repetitions are aligned
              asp_joined_content_sim = [:from, :to].map { |e| asp[e][:content_sim] }.join(' ')

              if asp[:has_repetitions]
                # ASP has repetitions. Return true if they are balanced.
                asp[:from][:repetitions].values.length == asp[:to][:repetitions].values.length
              else
                # ASP doesn't have repetitions and both :from and :to contain
                # the same count of each of cur's repeated phrases (0 or 1 times,
                # any more and they'd be flagged as having repetitions).
                cur_repeated_phrases.all? { |rep_phrase|
                  [:from, :to].map { |e|
                    asp[e][:content_sim].scan(rep_phrase).count
                  }.uniq.length == 1
                }
              end
            }
            high_sim_left = high_similarity_or_false(cur[:sim_left])
            high_sim_right = high_similarity_or_false(cur[:sim_right])

            # Check for possible left alignment, then right alignment
            if (
              # check for left alignment
              (
                # prev's right edge is aligned
                (prev && [:fully_aligned, :right_aligned].include?(prev[:type])) ||
                # or prev's repetitions are aligned and cur's repetitions are
                #    aligned or cur's and nxt's repetitions aren't.
                (prev_reps_aligned && (cur_reps_aligned || !nxt_reps_aligned)) ||
                # or there is no overlap between prev and cur (most expensive operation, do last)
                !asps_have_overlap(prev, cur, 0.9)
              ) && (
                # and left sim is high and higher than right sim
                high_sim_left && high_sim_left >= (high_sim_right || 0)
              )
            )
              cur[:type] = :left_aligned
            elsif (
              # check for right alignment
              (
                # nxt's left edge is aligned
                (nxt && [:fully_aligned, :left_aligned].include?(nxt[:type])) ||
                # or nxt's repetitions are aligned and cur's repetitions are
                #    aligned or cur's and prev's repetitions aren't.
                (nxt_reps_aligned && (cur_reps_aligned || !prev_reps_aligned))
                # or there is no overlap between cur and nxt (most expensive operation, do last)
                !asps_have_overlap(cur, nxt, 0.9)
              ) && (
                # and right sim is high and higher than left sim
                high_sim_right && high_sim_right > (high_sim_left || 0)
              )
            )
              cur[:type] = :right_aligned
            else
              # Nothing to do, leave :unaligned
            end
          end

          # Returns true if asp1 and asp2 have text overlap
          # @param asp1 [AlignedSubtitlePair]
          # @param asp2 [AlignedSubtitlePair]
          # @param sim_threshold [Float]
          # @return [Boolean]
          def asps_have_overlap(asp1, asp2, sim_threshold)
            StringComputations.overlap(
              asp1[:to][:content_sim],
              asp2[:from][:content_sim],
              sim_threshold
            ) > 0 ||
            StringComputations.overlap(
              asp1[:from][:content_sim],
              asp2[:to][:content_sim],
              sim_threshold
            ) > 0
          end

          # Returns difference in subtitles from :from to :to in al_st_pair.
          # @param al_st_pair [AlignedSubtitlePair]
          # @return [Integer]
          def compute_subtitle_count_change(al_st_pair)
            al_st_pair[:to][:subtitle_count] - al_st_pair[:from][:subtitle_count]
          end

          # Returns nature of asp.
          # @param asp [AlignedSubtitlePair]
          # @return [Symbol]
          def compute_subtitle_pair_type(asp)
            # check for gap first, so that we can assume presence of content in later checks.
            if 1 == asp[:subtitle_count_change]
              # Subtitle was added
              :st_added
            elsif -1 == asp[:subtitle_count_change]
              # Subtitle was removed
              :st_removed
            else
              # No ins/del, compute alignment
              high_sim_left = high_similarity_or_false(asp[:sim_left])
              high_sim_right = high_similarity_or_false(asp[:sim_right])
              no_repetitions = !asp[:has_repetitions]
              if(
                asp[:sim_abs].first > 0.93 and asp[:sim_abs].last >= 1.0 and
                high_sim_left and
                high_sim_right
              )
                # very high absolute similarity, sufficient confidence
                :fully_aligned
              elsif no_repetitions && high_sim_left && high_sim_right
                # Both similarities score high, use max
                high_sim_left >= high_sim_right ? :left_aligned : :right_aligned
              elsif no_repetitions && high_sim_left
                # very high left similarity, sufficient confidence
                :left_aligned
              elsif no_repetitions && high_sim_right
                # very high right similarity, sufficient confidence
                :right_aligned
              else
                # Some pairs that are aligned but have repetitions may land
                # here. We'll fix them in #fix_alignment_issues_around_subtitles_with_repeated_phrases!
                :unaligned
              end
            end
          end

          # @param reps_from [Hash] {"repeated_text"=>[0, 23, 41, 60]}
          # @param reps_to [Hash]
          def compute_repetitions(reps_from, reps_to)
            [reps_from, reps_to].any? { |reps| reps.any? { |k,v| v.length > 1 } }
          end

          # Returns a high similarity if it meets requirements or false otherwise.
          # @param asp_sim [Array<Float>] one of the asp's :sim_left or :sim_right
          #     values: `sim_left: [sim<Float>, conf<Float>]`
          # @return [Float, False]
          def high_similarity_or_false(asp_sim)
            # first is similarity, last is confidence
            (asp_sim.first >= 0.93 && asp_sim.last >= 0.9) ? asp_sim.first : false
          end

        end
      end
    end
  end
end
