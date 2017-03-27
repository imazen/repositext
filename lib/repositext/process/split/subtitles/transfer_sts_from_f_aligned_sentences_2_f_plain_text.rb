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

            f_p_pt_w_st_a_c_o = post_process_f_plain_text(
              raw_f_pt_w_st,
              f_st_confs
            )
            return f_p_pt_w_st_a_c_o  if !f_p_pt_w_st_a_c_o.success?
            f_p_pt_w_st, f_st_confs = f_p_pt_w_st_a_c_o.result

            if debug
              puts
              puts "comparing foreign captions".color(:red)
              f_ss_captions = f_ss.map { |e| e.split(/(?=@)/) }.flatten.map(&:strip)
              f_pt_captions = f_p_pt_w_st.split(/(?=@)/).map(&:strip)
              while f_ss_captions.any? || f_pt_captions.any?
                f_ss_caption = ''
                f_pt_caption = ''
                f_ss_caption = f_ss_captions.shift  until (f_ss_caption.nil? || f_ss_caption =~ /\A@/)
                f_pt_caption = f_pt_captions.shift  until (f_pt_caption.nil? || f_pt_caption =~ /\A@/)
                puts f_ss_caption.inspect
                puts f_pt_caption.inspect
                # Remove @, whitespace and digits
                f_ss_matching = (f_ss_caption || '').gsub(/[@\s\d]/, '')
                f_pt_matching = (f_pt_caption || '').gsub(/[@\s\d]/, '')
                max_len = [f_ss_matching.length, f_pt_matching.length, 10].min
                if f_ss_matching[0,max_len] != f_pt_matching[0,max_len]
                  puts "  captions have differences".color(:red)
                end
                puts
              end
              f_ss_st_count = f_ss.inject(0) { |m,e| m += e.count('@'); m }
              f_p_pt_w_st_st_count = f_p_pt_w_st.count('@')
              if f_ss_st_count != f_p_pt_w_st_st_count
                raise "Mismatch in subtitle counts: f_ss has #{ f_ss_st_count }, f_p_pt_w_st has #{ f_p_pt_w_st_st_count }"
              end
            end # debug

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
            f_s = working_f_ss.shift # Get first foreign sentence
            f_s_conf = f_s_confs.shift # Get first foreign sentence confidence
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
              elsif(ws = s.scan(/[ \n]/))
                # space or newline, append to new_f_pt
                if debug
                  puts " - whitespace match"
                end
                new_f_pt << ws
              elsif(
                # NOTE: LF Aligner converts certain unicode characters to regular
                # ASCII chars. So far we have encountered the following cases:
                #  * 0x00A0 => regular space
                # In order to handle this, we need two regexes, one for sentences
                # (_ss suffix, using ascii characters), and one for plain text
                # (_pt suffix, using original unicode characters).
                (n_w_pt = s.check(/[^[:space:]…\(]*[[:space:]…\(]?/)) &&
                (
                  n_w_ss = n_w_pt.gsub(/\u00A0/, ' ')
                  n_w_regexp_pt = Regexp.new(Regexp.escape(n_w_pt.rstrip) + "[[:space:]]?")
                  puts "n_w_regexp_pt: #{ n_w_regexp_pt.inspect }"  if debug
                  n_w_regexp_ss = Regexp.new(Regexp.escape(n_w_ss.rstrip) + "[[:space:]]?")
                  puts "n_w_regexp_ss: #{ n_w_regexp_ss.inspect }"  if debug
                  true
                ) &&
                (f_s_wo_st =~ /\A#{ n_w_regexp_ss }/)
              )
                # The next (actual) sentence in f_s is not aligned with f_pt.
                # This occurs when the sentence aligner has to merge sentences
                # to make alignment work. The sentence may span across paragraph
                # boundaries in f_pt. So we need to capture word by word:
                # * Append n_w_pt to new_f_pt
                # * Advance string scanner to end of n_w_pt
                # * Remove n_w_ss from f_s_wo_st
                # * Remove n_w_ss from f_s
                # * Transfer any subtitles encountered in f_s
                # * Track partial match mode
                # We track partial_match_active to block complete matches
                # higher up. We have to complete the partial match before we
                # can try a new complete match. Otherwise we'll get duplicate
                # content.
                partial_match_active = true # go into partial_match mode
                r = '' # container to collect string to be appended to new_f_pt

                # Handle subtitles in f_s
                if (num_sts_in_f_s = f_s.count('@')) > 0
                  # Remove sts from f_s
                  f_s.gsub!('@', '')
                  # Add sts to beginning of r
                  r << '@' * num_sts_in_f_s
                end

                # Before I transfer n_w_pt I recapture it using n_w_regexp_pt
                # which has an optional whitespace capture group added.
                # This is necessary in cases where I have an elipsis (already
                # part of n_w_pt) followed by a \n. If I don't recapture, the \n
                # will get lost.
                r << s.scan(n_w_regexp_pt) # transfer n_w_pt and advance string scanner position
                f_s_wo_st.sub!(n_w_regexp_ss, '') # remove n_w_ss from f_s_wo_st
                f_s.sub!(n_w_regexp_ss, '') # remove n_w_ss from f_s

                # Append r to new_f_pt
                new_f_pt << r

                if debug
                  puts " - fas2fpt - partial match: #{ n_w_ss.inspect }"
                  puts "   rx:        #{ n_w_regexp_ss.inspect }"
                  puts "   f_s:       #{ f_s.inspect }"
                  puts "   f_s_wo_st: #{ f_s_wo_st.inspect }"
                  puts "   s.rest:    #{ s.rest[0,100].inspect }"
                end

              elsif partial_match_active && '' == f_s_wo_st
                # We've consumed all words in f_s_wo_st, get next foreign sentence

                # Check if there are still any subtitles in f_s and transfer them.
                if f_s =~ /\A@+/
                  # transfer sts we encounter in f_s
                  new_f_pt << f_s[/\A@+/]
                  # Remove sts (and optional trailing whitespace) from f_s
                  f_s.sub!(/\A@+[[:space:]]?/, '')
                end

                if debug
                  puts "   Finished partial match!"
                end

                get_next_foreign_sentence = true
                partial_match_active = false
              elsif !get_next_foreign_sentence
                puts "f_s:       #{ f_s.inspect }"
                puts "f_s_wo_st: #{ f_s_wo_st.inspect }"
                raise "Handle this: #{ s.rest[0,20].inspect }"
              end

              if get_next_foreign_sentence
                if working_f_ss.any?
                  # There are more sentences to process, get next one.
                  f_s = working_f_ss.shift # Get next foreign sentence
                  if debug
                    puts "starting new f_s: #{ f_s.inspect }"
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
                puts "new_f_pt tail:  #{ new_f_pt[-[250,new_f_pt.length].min, 250].inspect }"
              end
            end

            Outcome.new(true, [new_f_pt, f_st_confs])
          end

          # @param raw_f_pt [String] the raw foreign plain text with subtitles.
          # @param f_st_confs [Array<Float>] Array with foreign subtitle confidences.
          # @return [Outcome] with foreign plain text _with_ subtitles and confidences as result.
          def post_process_f_plain_text(raw_f_pt, f_st_confs)
            # Fix any paragraphs that don't start with a subtitle.
            puts "fas2fpt: post_process_f_plain_text"  if debug

            p_f_pt_lines = []
            raw_f_pt.split("\n").each_with_index { |pt_line, idx|
              puts "  pt_line: #{ pt_line.inspect }"  if debug
              # Skip any header lines
              if pt_line =~ /\A\#/
                # Leave line as is (we need the header prefix later)
                puts "   * Header, leave as is"  if debug
                p_f_pt_lines << pt_line
                next
              end
              # Skip horizontal rule lines
              if "* * *" == pt_line
                puts "   * Horizontal rule, leave as is"  if debug
                p_f_pt_lines << pt_line
                next
              end

              # Move subtitle marks to before pargraph numbers
              pt_line.gsub!(/\A(\d+) @/, '@\1 ')

              # If line still doesn't start with subtitle mark, move it there
              # from somewhere else (the previous line, or a later stm on current)
              if pt_line !~ /\A@/
                puts "   * pt_line doesn't start with subtitle mark"  if debug
                prev_line = p_f_pt_lines[idx - 1]
                # Line doesn't start with subtitle_mark.
                # Move closest subtitle_mark to beginning of line.

                # Look for closest stm on previous line
                prev_txt = if(prev_stm_md = prev_line.match(/@([^@]*)\z/))
                  prev_stm_md[1]
                else
                  nil
                end

                # Look for closest stm on current line
                foll_txt = if(foll_stm_md = pt_line.match(/\A([^@]*)@/))
                  # Curr line has stm, capture text before first stm
                  foll_stm_md[1]
                else
                  nil
                end

                # Decide which stm to use
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
                puts "     * which_stm_to_use: #{ which_stm_to_use.inspect }"  if debug

                # Move chosen stm
                case which_stm_to_use
                when :none
                  # Nothing to do
                when :previous
                  # Remove last subtitle mark from previous line and prepend it
                  # to current line.
                  prev_line.sub!(/@#{ Regexp.escape(prev_txt) }\z/, prev_txt)
                  pt_line.prepend('@')
                when :following
                  # Move first stm to beginning of line
                  pt_line.sub!(/\A#{ Regexp.escape(foll_txt) }@/, "@#{ foll_txt }")
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

              puts "  new pt_line: #{ pt_line.inspect }"  if debug
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
