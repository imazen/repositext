class Repositext
  class Process
    class Split
      class Subtitles

        # This name space provides methods for transferring subtitles from
        # foreign aligned sentences to foreign plain text.
        module TransferStsFromFAlignedSentences2FPlainText

          # @param f_ss [Array<String>] the foreign sentences with subtitles.
          # @param f_pt [String] foreign plain text without subtitles.
          # @param f_s_confs [Array<Float>] an array with confidence levels for
          #   each foreign sentence.
          # @param remove_existing_sts [Boolean] if true will remove any
          #   subtitle_marks that already exist in f_cat.
          # @return [Outcome] with foreign plain text _with_ subtitles and
          #   Array of subtitle confidences as result.
          def transfer_sts_from_f_aligned_sentences_2_f_plain_text(f_ss, f_pt, f_s_confs, remove_existing_sts)
            if !remove_existing_sts && f_pt.index('@')
              # f_pt has unexpected subtitle_marks, raise
              raise(
                ArgumentError.new(
                  "You are trying to autosplit subtitles on a file that already has subtitles. " +
                  "If this is your intention, use the '--remove-existing-sts' flag."
                )
              )
            end

            working_f_ss = f_ss.deep_copy # so that we don't mutate the original data
            if working_f_ss.length != f_s_confs.length
              raise ArgumentError.new("Mismatch in sentences and confidences!")
            end

            prepared_f_pt = pre_process_foreign_plain_text(f_pt, remove_existing_sts)

            f_pt_w_st_o = transfer_sts_from_sentences_to_plain_text(
              working_f_ss,
              prepared_f_pt,
              f_s_confs
            )
            return f_pt_w_st_o  if !f_pt_w_st_o.success?
            raw_f_pt_w_st, f_st_confs = f_pt_w_st_o.result

            validate_that_no_plain_text_content_was_changed(f_pt, raw_f_pt_w_st)



            f_p_pt_w_st_a_c_o = post_process_plain_text(
              raw_f_pt_w_st,
              f_st_confs
            )
            return f_p_pt_w_st_a_c_o  if !f_p_pt_w_st_a_c_o.success?
            f_p_pt_w_st, f_st_confs = f_p_pt_w_st_a_c_o.result

            validate_that_no_plain_text_content_was_changed(f_pt, f_p_pt_w_st)
            validate_same_number_of_sts_in_as_and_pt(f_ss, f_p_pt_w_st)

            # Return outcome of post-processing
            f_p_pt_w_st_a_c_o
          end

          # Prepares plain text
          # @param f_pt [String] raw plain text
          # @param remove_existing_sts [Boolean]
          # @return [String]
          def pre_process_foreign_plain_text(f_pt, remove_existing_sts)
            remove_existing_sts ? f_pt.gsub('@', '') : f_pt
          end

          # @param f_ss [Array<String>] the foreign sentences with subtitles.
          # @param f_pt [String] foreign plain text without subtitles.
          # @param f_s_confs [Array<Float>] Array with foreign sentence subtitle confidences.
          # @return [Outcome] with raw foreign plain text _with_ subtitles and
          #   Array of sentence confidences as result.
          def transfer_sts_from_sentences_to_plain_text(f_ss, f_pt, f_s_confs)
            working_f_ss = f_ss.deep_copy
            new_f_pt = ''
            f_st_confs = [] # Container for converting confidences from sentence to subtitle level.
            s = StringScanner.new(f_pt)

            # Prepare first iteration
            f_s = working_f_ss.shift # Get next foreign sentence
            f_s_conf = f_s_confs.shift # Get next foreign sentence confidence
            f_st_confs += [f_s_conf] * f_s.count('@') # Add a confidence value for each subtitle in sentence
            f_s_wo_st = f_s.gsub('@', '') # Get foreign sentence without subtitles
            get_next_foreign_sentence = false
            partial_match_active = false

            # Scan through f_pt and rebuild new_f_pt
            while(f_s && !s.eos?) do

              if debug
                puts
                puts "new StringScanner iteration:"
                puts "s.rest:    #{ s.rest[0,150].inspect }"
              end

              # check for various matches. Start with most specific
              # matches and go to more general ones.
              if !partial_match_active && s.scan(Regexp.new(Regexp.escape(f_s_wo_st)))
                # Sentence without subtitles matches in its entirety,
                # append sentence with subtitles to new_f_pt.
                if debug
                  puts " - complete match:"
                  puts "   f_s: #{ f_s.inspect }"
                end
                new_f_pt << f_s
                get_next_foreign_sentence = true
              elsif(s.beginning_of_line? && (pn = s.scan(/\d+ /)))
                # A paragraph number that is in pt but not in sentence,
                # append to new_f_pt
                if debug
                  puts " - pn match"
                end
                new_f_pt << pn
              elsif(
                (n_w = s.check(/[^\s…\(]*[\s…\(]?/)) &&
                (n_w_regexp = Regexp.new(Regexp.escape(n_w.rstrip) + "\\s?")) &&
                (f_s_wo_st =~ /\A#{ n_w_regexp }/)
              )
                # The next (actual) sentence in f_s is not aligned with f_pt.
                # This occurs when the sentence aligner has to merge sentences
                # to make alignment work. The sentence may span across paragraph
                # boundaries in f_pt. So we need to capture word by word:
                # * Append n_w to new_f_pt
                # * Advance string scanner to end of n_w
                # * Remove n_w from f_s_wo_st
                # * Remove n_w from f_s
                # * Transfer any subtitles encountered in f_s
                # * Track partial match mode
                # We track partial_match_active to block complete matches
                # higher up. We have to complete the partial match before we
                # can try a new complete match. Otherwise we'll get duplicate
                # content.
                partial_match_active = true # go into partial_match mode
                # Check if f_s starts with subtitle and transfer it
                if f_s =~ /\A@/
                  # transfer sts we encounter in f_s
                  new_f_pt << '@'
                  # Remove st (and optional trailing whitespace) for f_s
                  f_s.sub!(/\A@\s?/, '')
                end
                # Before I transfer n_w I recapture it using n_w_regexp which
                # has an optional whitespace capture group added. This is
                # necessary in cases where I have an elipsis (already part of n_w)
                # followed by a \n. If I don't recapture, the \n will get lost.
                new_f_pt << s.scan(n_w_regexp) # transfer n_w and advance string scanner position
                f_s_wo_st.sub!(n_w_regexp, '') # remove n_w from f_s_wo_st
                f_s.sub!(n_w_regexp, '') # remove n_w from f_s

                if debug
                  puts " - fas2fpt - partial match: #{ n_w.inspect }"
                  puts "   rx:        #{ n_w_regexp.inspect }"
                  puts "   f_s:       #{ f_s.inspect }"
                  puts "   f_s_wo_st: #{ f_s_wo_st.inspect }"
                  puts "   s.rest:    #{ s.rest[0,100].inspect }"
                end
              elsif(ws = s.scan(/[ \n]/))
                # space or newline, append to new_f_pt
                if debug
                  puts " - whitespace match"
                end
                new_f_pt << ws
              elsif partial_match_active && '' == f_s_wo_st
                # We've consumed all words in f_s_wo_st, get next foreign sentence
                if debug
                  puts "   Finished partial match!"
                end
                get_next_foreign_sentence = true
                partial_match_active = false
              elsif !get_next_foreign_sentence
                puts "f_s:       #{ f_s.inspect }"
                raise "Handle this: #{ s.rest[0,20].inspect }"
              end

              if get_next_foreign_sentence
                if working_f_ss.any?
                  # There are more sentences to process, get next one.
                  f_s = working_f_ss.shift # Get next foreign sentence
                  if debug
                    puts "next f_s: #{ f_s.inspect }"
                  end
                  f_s_conf = f_s_confs.shift # Get next foreign sentence confidence
                  f_st_confs += [f_s_conf] * f_s.count('@') # Add a confidence value for each subtitle in sentence
                  f_s_wo_st = f_s.gsub('@', '') # Get foreign sentence without subtitles
                  get_next_foreign_sentence = false
                else
                  # Set f_s to nil to terminate while loop.
                  f_s = nil
                end
              end

              if debug
                puts "new_f_pt:  #{ new_f_pt[-250, 250].inspect }"
              end
            end

            Outcome.new(true, [new_f_pt, f_st_confs])
          end

          # @param raw_f_pt [String] the raw foreign plain text with subtitles.
          # @param f_st_confs [Array<Float>] Array with foreign subtitle confidences.
          # @return [Outcome] with foreign plain text _with_ subtitles and confidences as result.
          def post_process_plain_text(raw_f_pt, f_st_confs)
            # Fix any paragraphs that don't start with a subtitle.
            p_f_pt_lines = []
            raw_f_pt.split("\n").each_with_index { |pt_line, idx|

              # Skip any header lines
              if pt_line =~ /\A\#/
                # Leave line as is (we need the header prefix later)
                p_f_pt_lines << pt_line
                next
              end
              # Skip horizontal rule lines
              if "* * *" == pt_line
                p_f_pt_lines << pt_line
                next
              end

              # Move subtitle marks to before pargraph numbers
              pt_line.gsub!(/\A(\d+) @/, '@\1 ')

              # If line still doesn't start with subtitle mark, move it there
              # from somewhere else (the previous line, or a later stm on current)
              if pt_line !~ /\A@/
                prev_line = p_f_pt_lines[idx - 1]

                # Line doesn't start with subtitle_mark.
                # Move closest subtitle_mark to beginning of line.
                prev_txt = if(prev_stm_md = prev_line.match(/@([^@]*)\z/))
                  prev_stm_md[1]
                else
                  nil
                end

                # We look at text on the current line
puts "prev_txt: #{ prev_txt.inspect }"
                foll_txt = if(foll_stm_md = pt_line.match(/\A([^@]*)@/))
                  # Curr line has stm, capture text before first stm
                  foll_stm_md[1]
                else
                  nil
                end

                # Decide which stm to use
puts "foll_txt: #{ foll_txt.inspect }"
                matches_count = [prev_txt, foll_txt].compact.count
                which_stm_to_use = if 0 == matches_count
                  raise "Handle this!"
                elsif 1 == matches_count
                  # only one found, use it
                  prev_txt ? :previous : :following
                elsif 2 == matches_count
                  # Two found, use closer one
                  prev_txt.length < foll_txt.length ? :previous : :following
                else
                  raise "Handle this!"
                end

                # Move chosen stm
                case which_stm_to_use
                when :none
                  # Nothing to do
                when :previous
                  # Remove last subtitle mark from previous line and prepend it
                  # to current line.
                  prev_line.sub!("@#{ prev_txt }", prev_txt)
                  pt_line.prepend('@')
                when :following
                  # Move first stm to beginning of line
                  pt_line.sub!("#{ foll_txt }@", "@#{ foll_txt }")
                else
                  raise "Handle this!"
                end
              end

              # Clean up general subtitle_mark placement

              # Move subtitle marks to beginning of words
              # "word.@ word" => "word. @word"
              pt_line.gsub!(/@ (?=\S)/, ' @')

              # Move spaces inside subtitle_marker sequences to beginning of the
              # sequence "word.@@@@@ @word" => "word. @@@@@@word"
              pt_line.gsub!(/(@+) (@+)/, ' \1\2')

              # Move subtitle_marks to the outside of closing quote marks
              # "word.@” word" => "word.” @word"
              pt_line.gsub!(/@” (?=\w)/, '” @')

              # Move subtitle_marks to the outside of closing parens
              # "word.@) word" => "word.) @word"
              pt_line.gsub!(/@\) (?=\w)/, ') @')

              p_f_pt_lines << pt_line
            }

            Outcome.new(true, [p_f_pt_lines.join("\n"), f_st_confs])
          end

          # Raises an exception if any content was changed
          # @param f_pt [String] the original foreign plain text
          # @param f_p_pt_w_st [String] post processed foreign plain text with subtitles added
          def validate_that_no_plain_text_content_was_changed(f_pt, f_p_pt_w_st)
            # Remove subtitles and temporary header prefixes in both texts
            # (f_pt may already have sts)
            f_pt_wo_st = f_pt.gsub('@', '').gsub(/^\#/, '')
            f_p_pt_wo_st = f_p_pt_w_st.gsub('@', '').gsub(/^\#/, '')
            if f_p_pt_wo_st != f_pt_wo_st
              diffs = Suspension::StringComparer.compare(f_pt_wo_st, f_p_pt_wo_st)
              raise "Text mismatch between original plain text and plain text with subtitles: #{ diffs.inspect }"
            end
            true
          end

          # Raises an exception if foreign sentences and foreign plain text
          # have different numbers of subtitles.
          # @param f_ss [Array<String>] the foreign sentences with subtitles.
          # @param f_pt [String] the new foreign plain text with subtitles.
          def validate_same_number_of_sts_in_as_and_pt(f_ss, f_pt)
            f_ss_st_count = f_ss.inject(0) { |m,e| m += e.count('@'); m }
            f_pt_st_count = f_pt.count('@')
            if f_ss_st_count != f_pt_st_count
              raise "Mismatch in subtitle counts: f_ss has #{ f_ss_st_count }, f_pt has #{ f_pt_st_count }"
            end
            true
          end

        end
      end
    end
  end
end
