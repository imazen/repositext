class Repositext
  class Process
    class Split
      class Subtitles

        # @param foreign_file [Repositext::RFile]
        def initialize(foreign_file, primary_file)
          raise ArgumentError.new("Invalid foreign_file: #{ foreign_file.inspect }")  unless foreign_file.is_a?(RFile)
          raise ArgumentError.new("Invalid primary_file: #{ primary_file.inspect }")  unless primary_file.is_a?(RFile)
          @foreign_file = foreign_file
          @primary_file = primary_file
        end

        # @return [Outcome]
        def split
          primary_sequence = compute_primary_sequence(@primary_file.contents, @primary_file.language)
          foreign_sequence = compute_foreign_sequence(@foreign_file.contents, @foreign_file.language)
          aligned_paragraph_pairs = compute_aligned_paragraph_pairs(primary_sequence, foreign_sequence)
          foreign_plain_text_with_subtitles = copy_subtitles_to_foreign_plain_text(aligned_paragraph_pairs)
          foreign_content_at_with_subtitles = Suspension::TokenReplacer.new(
            foreign_plain_text_with_subtitles,
            @foreign_file.contents
          ).replace(:subtitle_mark)
          foreign_content_at_with_adjusted_subtitles = adjust_subtitles(
            Text.new(foreign_content_at_with_subtitles, @foreign_file.language)
          )
          Outcome.new(true, foreign_content_at_with_adjusted_subtitles)
        end

      private

        # @param txt [String] the primary contents
        # @param language [Language] the primary language
        # @return [Sequence]
        def compute_primary_sequence(txt, language)
          primary_contents_with_subtitles_only = Suspension::TokenRemover.new(
            txt,
            Suspension::REPOSITEXT_TOKENS.find_all { |e|
              ![:header_atx, :subtitle_mark].include?(e.name)
            }
          ).remove
          primary_contents_with_subtitles_only = encode_document_for_paragraph_splitting(
            primary_contents_with_subtitles_only
          )
          compute_sequence(primary_contents_with_subtitles_only, language)
        end

        # @param txt [String] the foreign contents
        # @param language [Language] the foreign language
        # @return [Sequence]
        def compute_foreign_sequence(txt, language)
          foreign_contents_without_tokens = Suspension::TokenRemover.new(
            txt,
            Suspension::REPOSITEXT_TOKENS.find_all { |e|
              ![:header_atx].include?(e.name)
            }
          ).remove
          foreign_contents_without_tokens = encode_document_for_paragraph_splitting(
            foreign_contents_without_tokens
          )
          compute_sequence(foreign_contents_without_tokens, language)
        end

        # Computes a sequence of paragraphs and sentences from contents.
        # @param contents [String]
        # @param language [Language]
        # @return [Sequence]
        def compute_sequence(contents, language)
          Sequence.new(contents, language)
        end

        # Aligns sentences of primary_sequence and foreign_sequence.
        # @param primary_sequence [Sequence]
        # @param foreign_sequence [Sequence]
        # @return [Array<BilingualParagraphPair>] Array of aligned paragraph pairs.
        #   Depending on confidence in sentence alignment, each paragraph contains
        #   one btp for each sentence pair (for high confidence), or a single
        #   btp that contains the entire paragraph's text.
        def compute_aligned_paragraph_pairs(primary_sequence, foreign_sequence)
          primary_sequence.paragraphs.each_with_index.map { |primary_paragraph, idx|
            foreign_paragraph = foreign_sequence.paragraphs[idx]
            BilingualParagraphPair.new(
              compute_sanitized_aligned_text_pairs(primary_paragraph, foreign_paragraph)
            )
          }
        end

        # @param primary_paragraph [Paragraph]
        # @param foreign_paragraph [paragraph]
        # @return [Array<BilingualTextPair>]
        def compute_sanitized_aligned_text_pairs(primary_paragraph, foreign_paragraph)
          merge_low_confidence_text_pairs(
            merge_text_pairs_with_gaps(
              compute_raw_aligned_text_pairs(primary_paragraph, foreign_paragraph)
            )
          )
        end

        # @param primary_paragraph [Paragraph]
        # @param foreign_paragraph [paragraph]
        # @return [Array<BilingualTextPair>]
        def compute_raw_aligned_text_pairs(primary_paragraph, foreign_paragraph)
          Alignment.align_text(
            primary_paragraph.sentences.map { |e| e.contents }.join('|'),
            foreign_paragraph.sentences.map { |e| e.contents }.join('|')
          ).map { |aligned_sentence_pair|
            # [
            #   "primary_sentence_contents",
            #   "foreign_sentence_contents"
            # ]
            BilingualTextPair.new(
              Text.new(aligned_sentence_pair.first, primary_paragraph.language),
              Text.new(aligned_sentence_pair.last, foreign_paragraph.language)
            )
          }
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

        # Returns foreign text with subtitles inserted.
        # @param bilingual_paragraph_pairs [Array<BilingualParagraphPair>]
        # @return [String]
        def copy_subtitles_to_foreign_plain_text(bilingual_paragraph_pairs)
          r = bilingual_paragraph_pairs.map { |bilingual_paragraph_pair|
            bilingual_paragraph_pair.bilingual_text_pairs.map { |btp|
              insert_subtitles_into_foreign_text(btp.primary_contents, btp.foreign_contents)
            }
          }.map { |sentences|
            sentences.join(' ')
          }.join("\n")
          decode_document_after_paragraph_splitting(r)
        end

        # Inserts subtitles from primary_text into foreign_text
        # @param primary_text [String]
        # @param foreign_text [String]
        # @return [String] the foreign text with subtitles inserted.
        def insert_subtitles_into_foreign_text(primary_text, foreign_text)
          subtitle_count = primary_text.count('@')
          if 0 == subtitle_count
            # Return as is
            foreign_text
          elsif 1 == subtitle_count
            # Prepend one subtitle
            '@' << foreign_text
          else
            # Interpolate multiple subtitles
            interpolate_multiple_subtitles(primary_text, foreign_text)
          end
        end

        # @param foreign_text [Text] The foreign content AT with subtitles placed
        # @return [String] the adjusted contents
        def adjust_subtitles(foreign_text)
          Fix::MoveSubtitleMarksToNearbySentenceBoundaries.new(foreign_text).fix.result
        end

        # Inserts multiple subtitles based on word interpolation.
        # @param primary_text [String] a sentence or paragraph
        # @param foreign_text [String] a sentence or paragraph
        # @return [String] foreign text with subtitles inserted.
        def interpolate_multiple_subtitles(primary_text, foreign_text)
          primary_words = primary_text.split(' ')
          primary_subtitle_indexes = primary_words.each_with_index.inject([]) { |m, (word, idx)|
            m << idx  if word.index('@')
            m
          }
          foreign_words = foreign_text.split(' ')
          word_scale_factor = foreign_words.length / primary_words.length.to_f
          foreign_subtitle_indexes = primary_subtitle_indexes.map { |e|
            (e * word_scale_factor).floor
          }
          foreign_subtitle_indexes.each { |i| foreign_words[i].prepend('@') }
          foreign_words.join(' ')
        end

        # Decodes a document for paragraph splitting
        # @param txt [String]
        # @return [String]
        def encode_document_for_paragraph_splitting(txt)
          txt.gsub(/^#([^\n]+)\n\n/, '#\1' + "\n")
        end

        # Encodes a document after paragraph splitting
        # @param txt [String]
        # @return [String]
        def decode_document_after_paragraph_splitting(txt)
          txt.gsub(/^#([^\n]+)\n/, '#\1' + "\n\n")
        end

      end
    end
  end
end
