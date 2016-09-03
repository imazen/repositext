class Repositext
  class Process
    class Compute
      class SubtitleOperationsForFile
        module AlignSubtitlePairs

          # Aligns subtitle pairs.
          # @param sts_from [Array<SubtitleAttrs>]
          # @param sts_to [Array<SubtitleAttrs>]
          # @return [Array<Array>]
          def align_subtitle_pairs(sts_from, sts_to)
            asps = compute_aligned_subtitle_pairs(sts_from, sts_to)
            enriched_asps = enrich_aligned_subtitle_pair_attributes(asps)
          end

        private

          def compute_aligned_subtitle_pairs(sts_from, sts_to)
            st_count_from = sts_from.inject(0) { |m,e| m += e[:subtitle_count] }
            st_count_to = sts_to.inject(0) { |m,e| m += e[:subtitle_count] }
            total_subtitle_count_change = st_count_to - st_count_from
            diagonal_band_range = [
              (total_subtitle_count_change.abs * 1.2).round,
              10
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
              alignment_offset = st_to[:index] - st_from[:index]
              max_alignment_offset = [max_alignment_offset, alignment_offset].max
              {
                from: st_from,
                to: st_to
              }
            }
            if max_alignment_offset >= diagonal_band_range
              print " - diagonal_band_range too narrow for max offset of #{ max_alignment_offset }"
            end
            r
          end

          # {
          #   type: <:left_aligned|:right_aligned|:st_added...>
          #   subtitle_object: <# Repositext::Subtitle ...>
          #   sim_left: [sim<Float>, conf<Float>]
          #   sim_right: [sim<Float>, conf<Float>]
          #   sim_abs: [sim<Float>, conf<Float>]
          #   content_length_change: <Integer from del to add>
          #   subtitle_count_change: <Integer from del to add>
          #   from: [SubtitleAttrs]
          #   to: [SubtitleAttrs]
          #   index: <Integer> index of aligned st pair in file
          #   first_in_para: Boolean, true if asp is first in paragraph
          #   last_in_para: Boolean, true if aps is last in paragraph
          # }
          def enrich_aligned_subtitle_pair_attributes(aligned_subtitle_pairs)
            enriched_aligned_subtitle_pairs = []
            most_recent_existing_subtitle_id = nil # to create temp subtitle ids
            temp_subtitle_offset = 0
            # Compute truncation length for sim_left and sim_right. We only
            # consider the first/last 30 chars. This length is aligned with
            # max_conf_at_char_length in LcsSimilarityComputer.
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
                  tmp_attrs: {}
                )
              end
              st_obj.tmp_attrs[:before] = asp[:from][:content]
              st_obj.tmp_attrs[:after] = asp[:to][:content]
              asp[:subtitle_object] = st_obj

              # Compute various similarities between deleted and added content
              sim_text_from = asp[:from][:content_sim]
              sim_text_to = asp[:to][:content_sim]
              asp[:sim_left] = LcsSimilarityComputer.compute(
                sim_text_from,
                sim_text_to,
                half_truncation_length,
                :left
              )
              asp[:sim_right] = LcsSimilarityComputer.compute(
                sim_text_from,
                sim_text_to,
                half_truncation_length,
                :right
              )
              asp[:sim_abs] = LcsSimilarityComputer.compute(
                sim_text_from,
                sim_text_to,
                false # look at all chars, don't truncate
              )

              # Compute remaining attrs
              asp[:content_length_change] = sim_text_to.length - sim_text_from.length # neg means text removal
              asp[:subtitle_count_change] = compute_subtitle_count_change(asp)
              asp[:type] = compute_subtitle_pair_type(asp)
              asp[:index] = idx + 1 # one based subtitle index
              # Take first and last_in_para from :to st
# TODO: Check if this is the correct thing to do!
              asp[:first_in_para] = asp[:to][:first_in_para]
              asp[:last_in_para] = asp[:to][:last_in_para]
              enriched_aligned_subtitle_pairs << asp
            }
            enriched_aligned_subtitle_pairs
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
            elsif(
              al_st_pair[:sim_abs].first > 0.93 and al_st_pair[:sim_abs].last == 1.0 and
              al_st_pair[:content_length_change].abs <= 4
            )
              # very high absolute similarity, sufficient confidence
              :fully_aligned
            else
              # Check if it's left or right aligned
              high_sim_left = (
                al_st_pair[:sim_left].first >= 0.83 and al_st_pair[:sim_left].last >= 0.9
              ) ? al_st_pair[:sim_left].first : false
              high_sim_right = (
                al_st_pair[:sim_right].first >= 0.83 and al_st_pair[:sim_right].last >= 0.9
              ) ? al_st_pair[:sim_right].first : false
              if high_sim_left && high_sim_right
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
        end
      end
    end
  end
end
