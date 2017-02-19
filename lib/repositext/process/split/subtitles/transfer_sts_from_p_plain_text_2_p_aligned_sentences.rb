class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # primary plain text to primary aligned sentences.
        module TransferStsFromPrimaryPlainText2PrimaryAlignedSentences

          # Returns modified aligned sentence pairs (asp) where subtitle_marks
          # have been added to the primary sentences in locations where they
          # exist in the primary plain_text (p_pt).
          #
          # Types of chars encountered in p_pt:
          #   * subtitle_mark
          #   * newlines
          #   * matching_text (with text in the asp primary sentences)
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

            asp_w_sts_o = merge_new_p_sentences_into_asp(p_ss_w_st, asp)
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
              next nil  if p_s.nil? # return gaps as is

              new_s = '' # container for new sentence
              finalize_sentence = false

              while !finalize_sentence && !s.eos? do

                # check for various character types. Start with most specific
                # matches and go to more general ones.
                if s.scan(Regexp.new(Regexp.escape(p_s) + "\n?"))
                  # sentence matches in its entirety, append to new_s
                  # we also consume any trailing newlines
                  new_s << p_s
                  finalize_sentence = true
                elsif s.scan(/@/)
                  # subtitle_mark, append to new_s
                  new_s << '@'
                elsif s.scan(/ /)
                  # space, just consume, nothing else to do
                elsif(
                  (partial_sentence_caption = s.check(/[^@]+/)) &&
                  (
                    partial_sentence_caption_regexp = Regexp.new(
                      "\\A" + Regexp.escape(partial_sentence_caption)
                    )
                  ) &&
                  (p_s =~ partial_sentence_caption_regexp)
                )
                  # The next caption in p_pt is not aligned with sentence
                  # boundaries. Append caption to new_s, advance string scanner
                  # to end of caption, and remove partial_sentence_caption from
                  # p_s.
                  new_s << partial_sentence_caption
                  s.skip(partial_sentence_caption_regexp)
                  p_s.sub!(partial_sentence_caption_regexp, '')
                else
                  raise "Handle this: #{ s.rest[0,20].inspect }"
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
