class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # primary to foreign aligned sentences.
        module TransferStsFromPAlignedSentences2FAlignedSentences

          # @param asp [Array<Array<String, Nil>>] the aligned sentence pairs.
          #   [["p sentence 1", "f sentence 1"], ["p sentence 1", nil], ...]
          # @return [Outcome] with Array of foreign sentence and confidence as result.
          def transfer_sts_from_p_aligned_sentences_2_f_aligned_sentences(asp)
            asp_w_f_sts = []

            if debug
              puts "Transferring subtitles from primary to foreign sentences:".color(:blue)
            end

            # Remove any gaps in asp
            asp.each { |(p_s, f_s)|
              raise "Both sentences are empty"  if('' == p_s && '' == f_s)
              raise "Unexpected nil sentence"  if p_s.nil? || f_s.nil?

              if debug
                puts
                p p_s
              end

              if '' == p_s
                # Primary sentence gap:
                # * Append foreign sentence to previous foreign sentence.
                # * Reduce confidence.
                prev_f_s = asp_w_f_sts.last
                asp_w_f_sts[-1] = [
                  prev_f_s[0],
                  prev_f_s[1] + ' ' + f_s, # insert a space
                  0.0
                ]
                if debug
                  puts "  Removed primary gap"
                  puts "  prev asp: #{ asp_w_f_sts[-1].inspect }"
                end
              elsif '' == f_s
                # Foreign sentence gap:
                # * Append primary sentence to previous primary sentence so that
                #   subtitle count validation has correct data.
                # * Append primary subtitles to previous foreign sentence so
                #   that no subtitles are lost in foreign.
                # * Reduce confidence.
                prev_f_s = asp_w_f_sts.last
                asp_w_f_sts[-1] = [
                  prev_f_s[0] + ' ' + p_s,
                  prev_f_s[1] + ('@' * p_s.count('@')),
                  0.0
                ]
                if debug
                  puts "  Removed foreign gap"
                  puts "  prev asp: #{ asp_w_f_sts[-1].inspect }"
                end
              else
                # Complete pair, transfer subtitles to foreign sentence
                f_s_w_st_o = transfer_subtitles_to_foreign_sentence(p_s, f_s)
                f_s_w_st, f_s_conf = f_s_w_st_o.result
                p f_s_w_st  if debug
                asp_w_f_sts << [p_s, f_s_w_st, f_s_conf]
              end
            }

            # Return foreign_sentence and confidence, drop primary sentence
            f_s_w_sts = asp_w_f_sts.map { |e| e[1] }
            f_s_confs = asp_w_f_sts.map { |e| e[2] }

            validate_same_number_of_sts_in_p_and_f(asp_w_f_sts)

            Outcome.new(true, [f_s_w_sts, f_s_confs])
          end

          # Transfers subtitles from primary sentence to foreign sentence.
          # @param p_s [String] primary sentence with subtitles
          # @param f_S [String] foreign sentence without subtitles
          # @return [Outcome] with Array of foreign sentence and confidence as result.
          def transfer_subtitles_to_foreign_sentence(p_s, f_s)
            subtitle_count = p_s.count('@')
            if 0 == subtitle_count
              # Return as is
              puts "  * No subtitle found"  if debug
              Outcome.new(true, [f_s, 1.0])
            elsif((1 == subtitle_count) && (p_s =~ /\A@/))
              # Prepend one subtitle
              puts "  * Single subtitle, prepend to foreign sentence"  if debug
              Outcome.new(true, ['@' << f_s, 1.0])
            else
              transfer_subtitles(p_s, f_s)
            end
          end

          # Inserts multiple subtitles based on word interpolation.
          # @param p_s [String] primary sentence with subtitles
          # @param f_S [String] foreign sentence without subtitles
          # @return [Outcome] with Array of foreign sentence and confidence as result.
          def transfer_subtitles(p_s, f_s)
            if debug
              puts "  Transfer subtitles:"
              puts "  * p_s: #{ p_s.inspect }"
              puts "  * f_s: #{ f_s.inspect }"
            end
            # Determine if we can use punctuation signature for snapping.
            # Conditions: Each primary st is preceded by punctuation and primary
            # and foreign punctuation signatures are identical.
            sts_w_preceding_punct = p_s.scan(/(?:\S|^)\s?@/)
            all_sts_are_preceded_by_punct = sts_w_preceding_punct.all? { |e|
              e =~ /\A@/ || e =~ /\A[#{ regex_punctuation_chars }]/
            }

            # Determine and apply snapping strategy
            new_f_s_snapped_to_punctuation_o = if(
              all_sts_are_preceded_by_punct &&
              (
                p_punct_sig = p_s.scan(/([#{ regex_punctuation_chars }])|([^#{ regex_punctuation_chars }]+)/).map { |m1, m2|
                  m1 ? m1 : 'T'
                }.join
                f_punct_sig = f_s.scan(/([#{ regex_punctuation_chars }])|([^#{ regex_punctuation_chars }]+)/).map { |m1, m2|
                  m1 ? m1 : 'T'
                }.join
                punc_sig_sim = p_punct_sig.longest_subsequence_similar(f_punct_sig)
                if debug
                  puts "  * punctuation signatures:"
                  puts "  * p: #{ p_punct_sig.inspect }"
                  puts "  * f: #{ f_punct_sig.inspect }"
                  puts "  * sim: #{ punc_sig_sim.inspect }"
                end
                1.0 == punc_sig_sim
              )
            )
              # All primary subtitles are preceded by punctuation, and primary
              # and foreign punctuation signatures are identical.
              snap_subtitles_to_punctuation_signature(p_s, f_s)
            else
              # Do a simple character based interpolation for initial
              # subtitle_mark placement.
              new_f_s_raw = interpolate_subtitle_positions(p_s, f_s)
              # Snap subtitle_marks to nearby punctuation
              snap_subtitles_to_nearby_punctuation(p_s, new_f_s_raw)
            end
          end

          # @return [String]
          def regex_punctuation_chars
            # TODO: Replace some of these characters with language specific ones.
            Regexp.escape(".,;:!?)]…”—")
          end

          # @param p_s [String] primary sentence with subtitles
          # @param f_S [String] foreign sentence without subtitles
          # @return [Outcome] with Array of foreign sentence and confidence as result.
          def snap_subtitles_to_punctuation_signature(p_s, f_s)
            puts "  Snap subtitles to punctuation signature:"  if debug
            # Match text up to and including
            #   * next punctuation character and optional trailing space OR
            #   * optional trailing space and end of string
            # Note that there may be sequences of punctuation characters with
            # no other text between them, e.g., "), ", so we need to make the
            # text before the punctuation character optional.
            p_segs = p_s.scan(/[^#{ regex_punctuation_chars }]*(?:[#{ regex_punctuation_chars }]\s?|\s?\z)/)
            f_segs = f_s.scan(/[^#{ regex_punctuation_chars }]*(?:[#{ regex_punctuation_chars }]\s?|\s?\z)/)
            if debug
              puts "  p_segs:         #{ p_segs.inspect }"
              puts "  f_segs (befor): #{ f_segs.inspect }"
            end
            if p_segs.length != f_segs.length
              pp p_segs
              pp f_segs
              raise "Handle this!"
            end
            new_f_segs = []
            p_segs.each { |p_seg|
              puts "  p_seg: #{ p_seg.inspect }"  if debug
              f_seg = f_segs.shift
              if debug
                puts "  f_seg b: #{ f_seg.inspect }"
                puts "  p_seg =~ /\A@/: #{ p_seg =~ /\A@/ }"
              end
              if p_seg =~ /\A@/
                # Primary starts with stm
                # Remove one stm from foreign
                f_seg.sub!(/@/, '')
                # Prepend foreign segment with stm
                f_seg.prepend('@')
              end
              puts "  f_seg a: #{ f_seg.inspect }"  if debug
              new_f_segs << f_seg
            }
            puts "  f_segs (after): #{ new_f_segs.inspect }"  if debug
            Outcome.new(true, [new_f_segs.join, 1.0])
          end

          # @param p_s [String] primary sentence with subtitles
          # @param f_S [String] foreign sentence without subtitles
          # @return [String] the new f_s with subtitles inserted.
          def interpolate_subtitle_positions(p_s, f_s)
            puts "  inside #interpolate_subtitle_positions"  if debug
            primary_chars = p_s.chars
            primary_subtitle_indexes = primary_chars.each_with_index.inject([]) { |m, (char, idx)|
              m << idx  if '@' == char
              m
            }
            puts "  primary_subtitle_indexes: #{ primary_subtitle_indexes.inspect }"  if debug
            foreign_chars = f_s.chars
            char_scale_factor = foreign_chars.length / primary_chars.length.to_f
            foreign_subtitle_indexes = primary_subtitle_indexes.map { |e|
              (e * char_scale_factor).round
            }
            if debug
              puts "  char_scale_factor: #{ char_scale_factor.inspect }"
              puts "  foreign_subtitle_indexes: #{ foreign_subtitle_indexes.inspect }"
            end
            # Insert subtitles at proportional character position, may be inside
            # a word. We reverse the array so that earlier inserts don't affect
            # positions of later ones.
            foreign_subtitle_indexes.reverse.each { |i|
              foreign_chars.insert(i, '@')
            }
            # Re-build foreign sentence with subtitle_marks added
            r = foreign_chars.join
            puts "  new raw f_s:       #{ r.inspect }"  if debug
            # Move subtitle marks to beginning of word if they are inside a word
            r.gsub!(/(\w+)@(\w+)/, '@\1\2')
            puts "  new sanitized f_s: #{ r.inspect }"  if debug
            r
          end


          # @param p_s [String] primary sentence with subtitles
          # @param new_f_s_raw [String] foreign sentence with interpolated subtitles
          # @return [Outcome] with Array of foreign sentence and confidence as result.
          def snap_subtitles_to_nearby_punctuation(p_s, new_f_s_raw)
            puts "  Snap subtitles to nearby punctuation:"  if debug
            # Then we check if we can further optimize subtitle_mark positions:
            # If the subtitle mark comes after secondary punctuation in primary,
            # then we check if the same punctuation is nearby the position of
            # the corresponding foreign subtitle_mark.
            p_captions = p_s.split(/(?=@)/)
            f_captions = new_f_s_raw.split(/(?=@)/)
            if p_captions.length != f_captions.length
              raise ArgumentError.new("Mismatch in captions count: p_captions: #{ p_captions.length }, f_captions: #{ f_captions.length }.")
            end
            sentence_confidence = 1.0

            if debug
              puts "  p_captions:"
              pp p_captions
              puts "  f_captions (after interpolate):"
              pp f_captions
            end

            # Set max_snap_distance based on total sentence length. Range for
            # snap distance is from 10 to 40 characters.
            # Sentences range from 50 to 450 characters.
            max_snap_distance = (
              [
                [(p_s.length / 8.0), 10].max,
                40
              ].min
            ).round

            if debug
              puts "  max_snap_distance: #{ max_snap_distance.inspect }"
              p_punct_sig_w_st = p_captions.map { |p_cap| p_cap.scan(/[#{ regex_punctuation_chars }@]/).join }.join
              f_punct_sig_bef = f_captions.map { |f_cap| f_cap.scan(/[#{ regex_punctuation_chars }@]/).join }.join
            end

            p_captions.each_with_index do |curr_p_c, idx|

              next  if 0 == idx # nothing to do for first caption
              curr_f_c = f_captions[idx]
              next  if curr_f_c.nil?
              prev_f_c = f_captions[idx-1]
              prev_p_c = p_captions[idx-1]

              if debug
                puts "  curr_p_c: #{ curr_p_c.inspect }"
                puts "  prev_p_c: #{ prev_p_c.inspect }"
                puts "  curr_f_c: #{ curr_f_c.inspect }"
                puts "  prev_f_c: #{ prev_f_c.inspect }"
              end

              if(primary_punctuation_md = prev_p_c.match(/([#{ regex_punctuation_chars }])\s?\z/))
                puts "  p_st is preceded by punctuation!"  if debug
                # Previous caption ends with punctuation. Try to see if
                # there is punctuation nearby the corresponding foreign
                # subtitle_mark. Note that the foreign punctuation could be
                # different from the primary one.
                primary_punctuation = primary_punctuation_md[1]
                puts "  primary_punctuation: #{ primary_punctuation.inspect }"  if debug

                # Detect nearby foreign punctuation
                leading_punctuation, txt_between_punctuation_and_stm = if(
                  before_md = prev_f_c.match(
                    /([#{ regex_punctuation_chars }]+)\s?([^#{ regex_punctuation_chars }]{0,#{ max_snap_distance }}\s*)\z/
                  )
                )
                  # Previous foreign caption has punctuation shortly before
                  # current subtitle_mark.
                  [before_md[1], before_md[2]]
                else
                  [nil, nil]
                end
                txt_between_stm_and_punctuation, trailing_punctuation = if(
                  after_md = curr_f_c.match(
                    /\A@([^#{ regex_punctuation_chars }]{,#{ max_snap_distance }})([#{ regex_punctuation_chars }]+\s*)/
                  )
                )
                  # Current foreign caption has punctuation shortly after
                  # current subtitle_mark.
                  [after_md[1], after_md[2]]
                else
                  [nil, nil]
                end
                trailing_punctuation_str = (trailing_punctuation || '').strip

                if debug
                  puts "  leading:  #{ [leading_punctuation, txt_between_punctuation_and_stm].inspect }"
                  puts "  trailing: #{ [txt_between_stm_and_punctuation, trailing_punctuation].inspect }"
                end

                # Determine where to move the subtitle_mark
                matches_count = [txt_between_punctuation_and_stm, txt_between_stm_and_punctuation].compact.length
                snap_to = if 0 == matches_count
                  # No nearby punctuation found either before or after, nothing to do
                  :none
                elsif 1 == matches_count
                  if txt_between_punctuation_and_stm
                    # We only have nearby punctuation before the subtitle_mark
                    :before
                  elsif txt_between_stm_and_punctuation
                    # We only have nearby punctuation after the subtitle_mark
                    :after
                  else
                    raise "Handle this!"
                  end
                elsif 2 == matches_count
                  # We found nearby punctuation both before and after, use the
                  # same punctuation as primary (if different), or the closer one.
                  if leading_punctuation.index(primary_punctuation) && !trailing_punctuation_str.index(primary_punctuation)
                    # Only leading punctuation equals primary
                    :before
                  elsif !leading_punctuation.index(primary_punctuation) && trailing_punctuation_str.index(primary_punctuation)
                    # Only trailing punctuation equals primary
                    :after
                  elsif txt_between_punctuation_and_stm.length < txt_between_stm_and_punctuation.length
                    # We can't use punctuation type, use the closer one
                    :before
                  else
                    :after
                  end
                else
                  raise "Handle this!"
                end

                # Move subtitle_mark to closest punctuation
                case snap_to
                when :before
                  # Move text from end of prev_f_c to beginning of curr_f_c
                  curr_f_c.sub!(/\A(@?)/, '\1' + txt_between_punctuation_and_stm)
                  prev_f_c.sub!(
                    /#{ Regexp.escape(txt_between_punctuation_and_stm) }\z/,
                    ''
                  )
                  sentence_confidence *= 0.8

                  if debug
                    puts "  Move subtitle forward (#{ idx + 1 }), moved text: #{ txt_between_punctuation_and_stm.inspect }"
                    puts "   - prev_f_c: #{ prev_f_c.inspect }"
                    puts "   - curr_f_c: #{ curr_f_c.inspect }"
                  end

                when :after
                  # Move text from beginning of curr_f_c to end of prev_f_c
                  full_txt_to_move = txt_between_stm_and_punctuation + trailing_punctuation
                  prev_f_c << full_txt_to_move
                  curr_f_c.sub!(full_txt_to_move, '')
                  sentence_confidence *= 0.8

                  if debug
                    puts "  Move subtitle back (#{ idx + 1 }), moved text: #{ full_txt_to_move.inspect }"
                    puts "   - prev_f_c: #{ prev_f_c.inspect }"
                    puts "   - curr_f_c: #{ curr_f_c.inspect }"
                  end

                when :none
                  puts "  No nearby punctuation found!"  if debug
                else
                  raise "Handle this: #{ snap_to.inspect }"
                end
              end
            end

            if debug
              f_punct_sig_aft = f_captions.map { |f_cap| f_cap.scan(/[#{ regex_punctuation_chars }@]/).join }.join
              puts "  p_punct_sig:       #{ p_punct_sig_w_st.inspect }"
              puts "  f_punct_sig (aft): #{ f_punct_sig_aft.inspect }"
              puts "  f_punct_sig (bef): #{ f_punct_sig_bef.inspect }"
              puts "  f_captions (after): #{ f_captions.inspect }"
            end

            Outcome.new(true, [f_captions.join, sentence_confidence])
          end

          # Validates that in each pair primary and foreign have the same
          # number of subtitles.
          # @param asp_w_f_sts [Array<Array>] with first item p_s and second item f_s
          def validate_same_number_of_sts_in_p_and_f(asp_w_f_sts)
            p_st_count = asp_w_f_sts.inject(0) { |m,e| m += e[0].count('@') }
            f_st_count = asp_w_f_sts.inject(0) { |m,e| m += e[1].count('@') }
            if p_st_count != f_st_count
              if debug
                pp asp_w_f_sts
                puts "\n\n\n\n"
                puts "mismatches:".color(:red)
                asp_w_f_sts.each { |(primary,foreign,conf)|
                  pr_st_count = primary.count('@')
                  fo_st_count = foreign.count('@')
                  if pr_st_count != fo_st_count
                    puts '-' * 10
                    p primary
                    puts "pr_st_count: #{ pr_st_count }"
                    p foreign
                    puts "fo_st_count: #{ fo_st_count }"
                    puts "conf: #{ conf.inspect }"
                  end
                }
              end
              raise "Mismatch in subtitle counts: primary has #{ p_st_count } and foreign has #{ f_st_count }"
            end
            true
          end

        end
      end
    end
  end
end
