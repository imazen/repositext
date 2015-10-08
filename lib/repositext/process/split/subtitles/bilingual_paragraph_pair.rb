class Repositext
  class Process
    class Split
      class Subtitles

        # Represents a pair of corresponding paragraphs in primary and foreign language.
        class BilingualParagraphPair

          # Creates an instance of self from two aligned paragraphs with unaligned sentences.
          # @param primary_paragraph [Paragraph]
          # @param foreign_paragraph [Paragraph]
          def initialize(primary_paragraph, foreign_paragraph, confidence=1.0)
            raise ArgumentError.new("Invalid primary_paragraph: #{ primary_paragraph.inspect }")  unless primary_paragraph.is_a?(Paragraph)
            raise ArgumentError.new("Invalid foreign_paragraph: #{ foreign_paragraph.inspect }")  unless foreign_paragraph.is_a?(Paragraph)
            @primary_paragraph = primary_paragraph
            @foreign_paragraph = foreign_paragraph
            @confidence = confidence
          end

          # Returns aligned text pairs based on sentences.
          def aligned_text_pairs
            @aligned_text_pairs ||= compute_aligned_text_pairs(
              @primary_paragraph, @foreign_paragraph, @confidence
            )
          end

          # Return Hash with the following keys: max, min, mean, median
          def confidence_stats
            max = nil
            min = nil
            means = []
            medians = []
            aligned_text_pairs.each { |e|
              max = max.nil? ? e.confidence_stats[:max] : [max, e.confidence_stats[:max]].max
              min = min.nil? ? e.confidence_stats[:min] : [min, e.confidence_stats[:min]].min
              means << e.confidence_stats[:mean]
              medians << e.confidence_stats[:median]
            }
            {
              max: max,
              min: min,
              mean: means.mean,
              median: medians.median,
              count: aligned_text_pairs.length,
            }
          end

          def primary_contents
            @primary_paragraph.contents
          end

          def foreign_contents
            @foreign_paragraph.contents
          end

        private

          # @param primary_paragraph [Paragraph]
          # @param foreign_paragraph [paragraph]
          # @return [Array<BilingualTextPair>]
          def compute_aligned_text_pairs(primary_paragraph, foreign_paragraph, confidence)
            merge_low_confidence_text_pairs(
              merge_text_pairs_with_gaps(
                compute_raw_aligned_text_pairs(primary_paragraph, foreign_paragraph, confidence)
              )
            )
          end

          def compute_raw_aligned_text_pairs(primary_paragraph, foreign_paragraph, confidence)
            if 0.0 == confidence
              # TODO: alternatively we may check for empty contents in one of the paras
              # This pair contains a gap!
              [
                BilingualTextPair.new(
                  Text.new(primary_paragraph.contents.strip, primary_paragraph.language),
                  Text.new(foreign_paragraph.contents.strip, foreign_paragraph.language)
                )
              ]
            else
              Alignment.align_text(
                primary_paragraph.sentences.map { |e| e.contents }.join('|'),
                foreign_paragraph.sentences.map { |e| e.contents }.join('|')
              ).map { |aligned_sentence_pair|
                # Alignment returns all sentences in a region as array. We only
                # ever expect one sentence per array, however we join them with ' '
                # anyways to get a single string.
                BilingualTextPair.new(
                  Text.new(aligned_sentence_pair.first.join(' '), primary_paragraph.language),
                  Text.new(aligned_sentence_pair.last.join(' '), foreign_paragraph.language)
                )
              }
            end
          end

          class ConfidenceLevelEntry < Struct.new(:conf, :idx); end;

          # Merges any btps with gaps into following btp (or previous if btp with
          # gap is the last one). This method handles single and multiple btps
          # with gaps, adjacent or not. It has no side effects on the passed in btps.
          # @param btps [Array<BilingualTextPair>] an array of BilingualTextPairs
          # @return [Array<BilingualTextPair>]
          def merge_text_pairs_with_gaps(btps)
            # return as is if there are no gap btps
            return btps  if btps.none? { |e| 0.0 == e.confidence }
            btps_to_merge = []
            ret_val = []
            # detect index of last btp that doesn't have a gap (except last btp).
            # All gapped btps at the end will be merged into this one
            last_non_gap_btp_index = if (1 != btps.length) && (0.0 == btps.last.confidence)
              # More than one btps, and last one has gap
              last_non_gap_btp = btps.each_with_index.to_a.reverse.detect { |(btp, idx)|
                0.0 != btp.confidence
              }
              last_non_gap_btp ? last_non_gap_btp.last : nil
            else
              nil
            end

            btps.each_with_index { |btp, idx|
              if (last_non_gap_btp_index == idx)
                # This is the last non-gap btp, and there are gapped ones following
                # Collect btp into btps_to_merge so that any trailing gapped btps
                # will be merged into this one.
                btps_to_merge << btp
              elsif (1 == btp.confidence) || (btps.length == idx + 1)
                # Not a gap, or is last btp:
                # First finalize merging of gapped btps
                if btps_to_merge.any?
                  # Finalize collected lacking_confidence btps
                  # add btp to list of merged, no matter if it has gap or not
                  btps_to_merge << btp
                  # Add merged text pairs to return value
                  ret_val << BilingualTextPair.merge(btps_to_merge)
                  # reset variables
                  btps_to_merge = []
                else
                  # Non-gapped btp, and no pending btps_to_merge, add as is
                  ret_val << btp
                end
              else
                # Gapped btp: collect for merging
                btps_to_merge << btp
              end
            }
            # Return Array with merged BilingualTextPairs.
            ret_val
          end

          # @param btps [Array<BilingualTextPair>] an array of BilingualTextPairs
          # @return [Array<BilingualTextPair>]
          def merge_low_confidence_text_pairs(btps)
            # return as is if there are no gap btps
            return btps  if btps.all? { |e| 1.0 == e.confidence }

            confidence_level_entries = btps.each_with_index.map { |e, idx|
              ConfidenceLevelEntry.new(e.confidence, idx)
            }
            # compute confidence level groups
            clgs = confidence_level_entries.inject(
              {
                full: [], # full confidence
                gap: [], # a gap, no confidence
                lacking: [], # collector for all items that don't have :full confidence
                low: [], # extremely low confidence score
                medium: [], # less than :full, more than :low or :gap
              }
            ) { |m,cle|
              if 1.0 == cle.conf
                m[:full] << cle
              elsif 0 == cle.conf
                m[:gap] << cle
                m[:lacking] << cle
              elsif cle.conf > 0.2
                m[:medium] << cle
                m[:lacking] << cle
              else
                m[:low] << cle
                m[:lacking] << cle
              end
              m
            }
            # NOTE: We return btps as is at the beginning of the method if all btps
            # have full confidence.
            r = if (
              ( # only full and medium confidence, no adjacent pairs with medium
                clgs[:low].empty? &&
                clgs[:gap].empty? &&
                (
                  1 == clgs[:medium].length ||
                  clgs[:medium].each_cons(2).none? { |(first, second)|
                    # adjacent pair
                    first.idx.succ == second.idx
                  }
                )
              )
            )
              # No text pairs need to be merged, return as is
              btps
            elsif (
              # there are at least two lacking confidence pairs and they are adjacent
              (clgs[:lacking].length > 1) &&
              clgs[:lacking].each_cons(2).all? { |(first, second)|
                # adjacent pair
                first.idx.succ == second.idx
              }
            )
              # merge all lacking_confidence pairs
              merge_lacking_confidence_adjacent_pairs(btps)
            else
              # no full confidence btps, or more complex situations with
              # low confidence pairs:
              # Merge all sentences in paragraph together into single btp
              [BilingualTextPair.merge(btps)]
            end
          end

          # Merges any adjacent btps that lack confidence into one.
          # @param btps [Array<BilingualTextPair>]
          # @retun [Array<BilingualTextPair>]
          def merge_lacking_confidence_adjacent_pairs(btps)
            btps_to_merge = []
            ret_val = []
            btps.each_with_index { |btp, idx|
              if (1.0 == btp.confidence) || (btps.length == idx + 1)
                # Btp doesn't need to be merged, or is last btp:
                # First finalize merging of btps_to_merge
                if btps_to_merge.any?
                  # Finalize collected btps_to_merge
                  if 1.0 != btp.confidence
                    # current btp is lacking_confidence, merge
                    btps_to_merge << btp
                  end
                  # Add merged text pairs to return value
                  ret_val << BilingualTextPair.merge(btps_to_merge)
                  # reset collector
                  btps_to_merge = []
                end
                # Then add full confidence btp as is
                if 1.0 == btp.confidence
                  ret_val << btp
                end
              else
                # Lacking_confidence btp: collect for merging
                # (we do this even for standalone lacking_confidence btps)
                # it's a bit more work, however it keeps the app logic simpler.
                btps_to_merge << btp
              end
            }
            # Return Array with merged BilingualTextPairs.
            ret_val
          end

        end

      end
    end
  end
end
