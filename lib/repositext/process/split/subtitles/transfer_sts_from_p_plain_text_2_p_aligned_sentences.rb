class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # primary plain text to primary aligned sentences.
        module TransferStsFromPPlainText2PAlignedSentences

          # Returns modified aligned sentence pairs (asp) where subtitle_marks
          # have been added to the primary sentences in locations where they
          # exist in the primary plain_text (p_pt).
          #
          # Types of chars encountered in p_pt:
          #   * subtitle_marks - will be transferred
          #   * matching_text (with text in the asp primary sentences)
          #   * newlines and spaces between paragraphs and sentences.
          #
          # @param p_pt [String] primary plain text
          # @param asp [Array<Array<String, Nil>>] the aligned sentence pairs.
          #   [["p sentence 1", "f sentence 1"], ["p sentence 1", nil], ...]
          # @return [Outcome] with asp with primary subtitles as result.
          def transfer_sts_from_p_plain_text_2_p_aligned_sentences(p_pt, asp)
            p_sentences = asp.map { |e| e.first }

            # Rebuild sentences one at a time with subtitles added from p_pt
            p_ss_w_st_o = transfer_sts_from_plain_text_2_sentences(
              p_pt,
              p_sentences
            )
            return p_ss_w_st_o  if !p_ss_w_st_o.success?
            p_ss_w_st = p_ss_w_st_o.result

            merge_new_p_sentences_into_asp(p_ss_w_st, asp)
          end

          # Transfers subtitles from primary plain text (p_pt) to primary
          # sentences (p_ss).
          # @param p_pt [String] primary plain text
          # @param p_ss [Array<String] Primary sentences
          # @return [Outcome] with primary sentences with subtitles as result.
          def transfer_sts_from_plain_text_2_sentences(p_pt, p_ss)
            s = StringScanner.new(p_pt)

            # Iterate over all sentences and insert subtitles as needed
            p_ss_w_st = p_ss.map { |p_s|
              next ''  if '' == p_s # return gaps as is

              new_s = '' # container for new sentence
              finalize_sentence = false

              if debug
                puts
                puts "New p_s: #{ p_s.inspect }"
                puts "s.rest:  #{ s.rest[0,100].inspect }"
              end

              while !finalize_sentence && !s.eos? do

                # check for various character types. Start with most specific
                # matches and go to more general ones.
                if s.scan(Regexp.new(Regexp.escape(p_s)))
                  # sentence matches in its entirety, append to new_s
                  new_s << p_s
                  finalize_sentence = true
                elsif s.scan(/@/)
                  # subtitle_mark, append to new_s
                  new_s << '@'
                elsif(
                  (
                    # match up to first subtitle_mark, excluding optional preceding whitespace
                    partial_sentence_caption = s.check_until(/(?=(@|\s@))/)
                  ) &&
                  ('' != partial_sentence_caption) &&
                  (
                    puts(" - ppt2pas - partial match: #{ partial_sentence_caption.inspect }")  if debug
                    true
                  ) &&
                  (
                    # We build the regexp without trailing whitespace. p_s and
                    # p_pt may have different kinds of whitespace. E.g., if
                    # primary sentence consists of two (to make it match with
                    # foreign sentence), these two sentences may come from
                    # different paragraphs and may be separated by \n instead
                    # of a space character. So we build the regexp without the
                    # trailing space to make sure it matches anyways.
                    partial_sentence_caption_regexp = Regexp.new(
                      "\\A" + Regexp.escape(partial_sentence_caption)
                    )
                  ) &&
                  (p_s =~ partial_sentence_caption_regexp)
                )
                  # The next caption in p_pt is not aligned with sentence
                  # boundaries:
                  # * Re-scan partial_sentence_caption, capturing optional
                  #   trailing whitespace. This will also advance the string
                  #   scanner to the correct location.
                  # * Append caption to new_s
                  # * Remove partial_sentence_caption from p_s.
                  # * Preserve any trailing whitespace in partial sentence
                  #   caption. This whitespace exists in noth p_pt but not in p_s
                  # partial_sentence_caption_w_ws = s.scan(
                  #   /#{ partial_sentence_caption_regexp }\s*/
                  # )
                  new_s << partial_sentence_caption
                  s.skip(partial_sentence_caption_regexp)
                  p_s.sub!(partial_sentence_caption_regexp, '')
                  if(leading_ws = p_s.match(/\A\s+/))
                    # append the captured whitespace to new_s and remove it from p_s
                    new_s << leading_ws.to_s
                    p_s.lstrip!
                  end
                elsif s.scan(/\n/)
                  # Newline between two paragraphs. It exists in plain text only,
                  # just consume, nothing else to do
                elsif s.scan(/[ \u00A0\uFEFF]/)
                  # A space character between two sentences:
                  # * Regular space
                  # * non-breaking space (0x00A0)
                  # * zero width no-break space (0xFEFF)
                  # It exists in plain text only, just consume, nothing else to do.
                else
                  puts
                  puts "p_s:".color(:red) + "                     #{ p_s.inspect }"
                  puts "remaining p_pt:".color(:red) + "          #{ s.rest[0,150].inspect }"
                  puts "new_s:".color(:red) + "                   #{ new_s.inspect }"
                  puts "previously matched p_pt:".color(:red) + " #{ s.pre_match.inspect }"
                  raise "Handle this!"
                end
              end
              new_s
            }
            Outcome.new(true, p_ss_w_st)
          end

          # @param p_ss_w_st [Array<String] primary sentences with subtitles
          # @param asp [Array<Array<String, Nil>>] the aligned sentence pairs.
          #   [["p sentence 1", "f sentence 1"], ["p sentence 1", nil], ...]
          # @return [Array<Array<String, Nil>>] same structure as asp, with sts.
          def merge_new_p_sentences_into_asp(p_ss_w_st, asp)
            if p_ss_w_st.length != asp.length
              return Outcome.new(
                false,
                nil,
                ["Mismatch in sentence count! p_sentences: #{ p_ss_w_st.length }, asp: #{ asp.length }"]
              )
            end

            asp_w_sts = asp.each_with_index.map { |e, idx|
              # Use primary sentence with subtitles and existing foreign sentence
              [p_ss_w_st[idx], e.last]
            }
            Outcome.new(true, asp_w_sts)
          end
        end
      end
    end
  end
end
