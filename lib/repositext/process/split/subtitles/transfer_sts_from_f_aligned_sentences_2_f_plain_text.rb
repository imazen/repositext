class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # foreign aligned sentences to foreign plain text.
        module TransferStsFromFAlignedSentences2FPlainText

          # @param f_ss [Array<String>] the foreign sentences with subtitles.
          # @param f_pt [String] foreign plain text without subtitles.
          # @return [Outcome] with foreign plain text _with_subtitles as result.
          def transfer_sts_from_f_aligned_sentences_2_f_plain_text(f_ss, f_pt)
            f_pt_w_st_o = transfer_sts_from_sentences_to_plain_text(f_ss, f_pt)
            return f_pt_w_st_o  if !f_pt_w_st_o.success?
            raw_f_pt_w_st = f_pt_w_st_o.result

            f_p_pt_w_st_o = post_process_plain_text(raw_f_pt_w_st)
            return f_p_pt_w_st_o  if !f_p_pt_w_st_o.success?
            f_p_pt_w_st = f_p_pt_w_st_o.result

            validate_that_no_content_was_changed(f_pt, f_p_pt_w_st)

            # Return outcome of post-processing
            f_p_pt_w_st_o
          end

          # @param f_ss [Array<String>] the foreign sentences with subtitles.
          # @param f_pt [String] foreign plain text without subtitles.
          # @return [Outcome] with raw foreign plain text _with_subtitles as result.
          def transfer_sts_from_sentences_to_plain_text(f_ss, f_pt)
            new_f_pt = ''
            s = StringScanner.new(f_pt)
            f_s = f_ss.shift
            f_s_wo_st = f_s.gsub('@', '')
            get_next_foreign_sentence = false

            # # Scan through f_pt and rebuild new_f_pt
            while f_s && !s.eos? do
              # check for various matches. Start with most specific
              # matches and go to more general ones.
              if s.scan(Regexp.new(Regexp.escape(f_s_wo_st)))
                # sentence (with subtitles removed) matches in its entirety,
                # append sentence with subtitles to new_f_pt.
                new_f_pt << f_s
                get_next_foreign_sentence = true
              elsif(ws = s.scan(/[ \n]/))
                # space or newline, append to new_f_pt
                new_f_pt << ws
              elsif(s.beginning_of_line? && (pn = s.scan(/\d+ /)))
                # A paragraph number that is in pt but not in sentence,
                # append to new_f_pt
                new_f_pt << pn
              elsif(
                (n_w = s.check(/\S+\s?/)) &&
                (n_w_regexp = Regexp.new("\\A" + Regexp.escape(n_w.rstrip) + "\\s?")) &&
                (f_s_wo_st =~ n_w_regexp)
              )
                # The next (actual) sentence in f_s is not aligned with f_pt.
                # This occurs when the sentence splitter fails to detect a
                # sentence correctly. The sentence may span across paragraph
                # boundaries in f_pt. So we need to capture word by word.
                # Append n_w to new_f_pt, advance string scanner to end of
                # n_w and remove n_w from f_s
                new_f_pt << n_w
                s.skip(n_w_regexp)
                f_s_wo_st.sub!(n_w_regexp, '')
              elsif '' == f_s_wo_st
                # We've consumed all words in f_s_wo_st, get next foreign sentence
                get_next_foreign_sentence = true
              elsif !get_next_foreign_sentence
                raise "Handle this: #{ s.rest[0,20].inspect }"
              end

              if get_next_foreign_sentence
                f_s = f_ss.shift
                f_s_wo_st = f_s.gsub('@', '')  if f_s
                get_next_foreign_sentence = false
              end
            end

            Outcome.new(true, new_f_pt)
          end

          # @param raw_f_pt [String] the raw foreign plain text with subtitles
          # @return [Outcome] with foreign plain text _with_subtitles as result.
          def post_process_plain_text(raw_f_pt)
# TODO: implement this
            Outcome.new(true, raw_f_pt)
          end

          # Raises an exception if any content was changed
          # @param f_pt [String] the original foreign plain text
          # @param f_p_pt_w_st [String] post processed foreign plain text with subtitles added
          def validate_that_no_content_was_changed(f_pt, f_p_pt_w_st)
            # Remove subtitles
            f_p_pt_wo_st = f_p_pt_w_st.gsub('@', '')
            if f_p_pt_wo_st != f_pt
              raise "Plain text mismatch!"
            end
          end
        end
      end
    end
  end
end
