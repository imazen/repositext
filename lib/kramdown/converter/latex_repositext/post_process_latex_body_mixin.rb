module Kramdown
  module Converter
    class LatexRepositext
      # Namespace for methods related to post processing the latex body string.
      module PostProcessLatexBodyMixin

        # @param [String] latex_body
        def post_process_latex_body(latex_body)
          lb = latex_body.dup

          highlight_gap_marks_in_red!(lb)
          format_leading_and_trailing_eagles!(lb) # NOTE: Do this after processing gap_marks!
          remove_space_after_paragraph_numbers!(lb)
          set_line_break_positions!(lb)

          lb
        end

        # Highlights text following gap marks in red.
        # @param lb [String] latex body, will be modified in place.
        def highlight_gap_marks_in_red!(lb)
          # gap_marks: Skip certain characters and find characters to highlight in red
          gap_mark_complete_regex = Regexp.new(Regexp.escape(tmp_gap_mark_complete))
          l_ch = @options[:language].chars
          chars_to_skip = [
            l_ch[:d_quote_open],
            l_ch[:em_dash],
            l_ch[:s_quote_open],
            ' ',
            '(',
            '[',
            '"',
            "'",
            '}',
            '*',
            '［', # chinese bracket
            '（', # chinese parens
            '一', # chinese dash
            '《', # chinese left double angle bracket
          ].join
          lb.gsub!(
            /
              #{ gap_mark_complete_regex } # find tmp gap mark number and text
              ( # capturing group for first group of characters to be colored red
                (?: # non capturing group
                  #{ l_ch[:elipsis] } # elipsis
                  (?!#{ l_ch[:elipsis] }) # not followed by another elipsis so we exclude chinese double elipsis
                )? # optional
              )
              ( # capturing group for characters that are not to be colored red
                (?: # find one of the following, use non-capturing group for grouping only
                  [#{ Regexp.escape(chars_to_skip) }]+ # special chars or delimiters
                  | # or
                  …… # chinese double elipsis
                  | # or
                  \\[[:alnum:]]+\{ # latex command with opening {
                  | # or
                  \s+ # eagle followed by whitespace
                )* # any of these zero or more times to match nested latex commands
              )
              ( # capturing group for second group of characters to be colored red
                #{ l_ch[:elipsis] }? # optional elipsis
                [[:alpha:][:digit:]#{ l_ch[:apostrophe] }\-\?,]* # words and some punctuation
              )
            /x,
            # we move the tmp_gap_mark_number to the very beginning so that if we
            # have an ellipsis before a latex command, the gap_mark_number will be
            # in front of the entire section that is colored red.
            # \1: an optional ellipsis (colored red)
            # \2: an optional latex command or characters not to be colored red
            # \3: the text to be colored red
            # OPTIMIZATION: We could skip the first \RtGapMarkText if \1 is blank
            tmp_gap_mark_number + "\\RtGapMarkText" + '{\1}' + '\2' + "\\RtGapMarkText" + '{\3}'
          )
          # If in the gap_mark processing above regex ref \1 is empty, we end up
          # with empty `\RtGapMarkText{}` fragments. We remove them in this step:
          lb.gsub!("\\RtGapMarkText{}", '')
          # Move tmp_gap_mark_number to outside of quotes, parentheses and brackets
          if !['', nil].include?(tmp_gap_mark_number)
            gap_mark_number_regex = Regexp.new(Regexp.escape(tmp_gap_mark_number))
            chars_to_move_outside_of = [
              l_ch[:apostrophe],
              l_ch[:d_quote_open],
              l_ch[:s_quote_open],
              '(',
              '[',
            ].join
            lb.gsub!(
              /
                ( # capturing group for characters to move outside of
                  [#{ Regexp.escape(chars_to_move_outside_of) }]*
                )
                #{ gap_mark_number_regex } # find tmp gap mark number
              /x,
              tmp_gap_mark_number + '\1' # Reverse order
            )
            # Move tmp_gap_mark_number to after leading eagle
            lb.gsub!(
              /
                (#{ gap_mark_number_regex }) # capture group for tmp gap mark number
                \s? # followed by eagle and optional space
              /x,
              '\1' # Reverse order
            )
            # Convert tmp_gap_mark_number to latex command
            lb.gsub!(gap_mark_number_regex, "\\RtGapMarkNumber{}")
          end
          # Make sure no tmp_gap_marks are left
          if(ltgm = lb.match(/.{0,20}#{ Regexp.escape(tmp_gap_mark_text) }.{0,20}/))
            raise(LeftoverTempGapMarkError.new("Leftover temp gap mark: #{ ltgm.to_s.inspect }"))
          end
          if !['', nil].include?(tmp_gap_mark_number)
            if(ltgmn = lb.match(/.{0,10}#{ Regexp.escape(tmp_gap_mark_number) }.{0,10}/))
              raise(LeftoverTempGapMarkNumberError.new("Leftover temp gap mark number: #{ ltgmn.to_s.inspect }"))
            end
          end
        end

        # Replaces leading and trailing eagles with latex command/environment for
        # custom formatting.
        # @param lb [String] latex body, will be modified in place.
        def format_leading_and_trailing_eagles!(lb)
          # Replace leading eagle with RtFirstEagle
          lb.gsub!(
            /
              ^ # beginning of line
               # eagle
              \s* # zero or more whitespace chars
              ( # second capture group
                [^]{10,} # at least ten non eagle chars
              )
              (?!$) # not followed by line end
            /x,
            "\\RtFirstEagle{}" + '\1' # we use an environment for first eagle
          )
          # NOTE: We've had issues where PDF export hung forever on files that
          # didn't have a trailing eagle. So we run this processing step only
          # if at least one more eagle is present in lb.
          if lb.index('')
            # Replace trailing eagle with RtLastEagle
            lb.gsub!(
              /
                (?!<^) # not preceded by line start
                ( # first capture group
                  [^]{10,} # at least ten non eagle chars
                )
                \s # a single whitespace char
                 # eagle
                ( # second capture group
                  [^]{,3} # up to three non eagle chars
                  $ # end of line
                )
              /x,
              '\1' + "\\RtLastEagle{}" + '\2' # we use a command for last eagle
            )
            # Handle RtLastEagle inside of .song para: Songs have a wider
            # right margin than regular text, so the eagle is not as
            # close to the right margin as expected.
            # In order to push the trailing eagle further to the right
            # than the song paragraphs right margin, we move the
            # eagle into a new paragraph where it is positioned
            # further to the right, and shifted back up to be aligned
            # with the previous line of text.
            lb.gsub!(
              /\\RtLastEagle(\{\}\n\\end\{(?:RtSong|RtStanza)\})/,
              "\\RtLastEagleInsideSong{}" + '\1'
            )
          end
        end

        # Removes space after paragraph number to avoid fluctuations in indent.
        # @param lb [String] latex body, will be modified in place.
        def remove_space_after_paragraph_numbers!(lb)
          lb.gsub!(/(\\RtParagraphNumber\{[^\}]+\})\s*/, '\1')
        end

        # Determines where line breaks are allowed to happen.
        # @param lb [String] latex body, will be modified in place.
        def set_line_break_positions!(lb)
          l_ch = @options[:language].chars

          # Don't break lines between double open quote and apostrophe (via ~)
          lb.gsub!(
            "#{ l_ch[:d_quote_open] } #{ l_ch[:apostrophe] }",
            "#{ l_ch[:d_quote_open] }~#{ l_ch[:apostrophe] }"
          )

          # Insert zero-width space after all elipses, emdashes, and hyphens.
          # This gives latex the option to break a line after these characters.
          # \hspace{0pt} is the latex equivalent of zero-width space (&#x200B;)
          line_breakable_chars = Regexp.escape(
            [l_ch[:elipsis], l_ch[:em_dash], '-'].join
          )
          # Exceptions: Don't insert zero-width space if followed by no-break characters:
          no_break_following_chars = Regexp.escape(
            [
              l_ch[:s_quote_close],
              l_ch[:d_quote_close],
              ')?,!',
              "\u00A0", # non-breaking space
              "\u202F", # narrow non-breaking space
            ].join
          )
          # We only want to allow linebreak _after_ line_breakable_chars but not _before_.
          # We insert a \\nolinebreak to prevent linebreaks _before_.
          lb.gsub!(
            /
              (?<lbc> # named capture group
                [#{ line_breakable_chars }]
              )
              (?! # not followed by one of the following options
                (
                  [#{ no_break_following_chars }] # certain characters
                  |
                  #{ options[:ed_and_trn_abbreviations] } # language specific editor or translator abbreviations
                  |
                  \\RtLastEagle # last eagle latex command
                )
              )
            /ix,
            "\\nolinebreak[4]\\k<lbc>\\hspace{0pt}"
          )

          # When we adjust kerning in smallcaps emulation, the previous gsub!
          # inserts a \\nolinebreak[4]-\\hspace{0pt} between the opening brace
          # and the minus sign of either of any negative kerning values.
          # This gsub! undoes it. I chose to break it into a separate gsub! call
          # in order to keep the previous regex simpler:
          # Original latex:
          #     T\RtSmCapsEmulation{-0.1em}{EXT}
          # Modified by above gsub! to:
          #     T\RtSmCapsEmulation{\nolinebreak[4]-\hspace{0pt}0.1em}{EXT}
          # Here we revert it back to:
          #     T\RtSmCapsEmulation{-0.1em}{EXT}
          lb.gsub!("{\\nolinebreak[4]-\\hspace{0pt}", "{-")

          # We don't allow linebreaks _before_ or _after_ an emdash when followed
          # by some abbreviations.
          lb.gsub!(
            /
              #{ l_ch[:em_dash] }
              (
                #{ options[:ed_and_trn_abbreviations] }
              )
            /ix,
            "\\nolinebreak[4]" + l_ch[:em_dash] + "\\nolinebreak[4]" + '\1'
          )

          # We don't allow linebreaks before certain numbers:
          # `word 1` => `word~1`
          # lb.gsub!(/(?<=[a-z])\s(?=\d)/, "~")

          # We don't allow linebreaks between period and numbers:
          # `word .22` => `word .\\nolinebreak[4]22`
          lb.gsub!(/( \.)(\d)/, '\1' + "\\nolinebreak[4]" + '\2')

          # We don't allow linebreaks between the end of a control sequence and a period
          lb.gsub!("}.", "}\\nolinebreak[4].")

          # We don't allow linebreaks between a hyphen and an ellipsis when
          # followed by a closing quote mark
          lb.gsub!(
            "\\nolinebreak[4]-\\hspace{0pt}…#{ l_ch[:d_quote_close] }",
            "\\nolinebreak[4]-\\nolinebreak[4]…#{ l_ch[:d_quote_close] }"
          )

          # We don't allow linebreaks between chinese period and closing bracket
          lb.gsub!("。]", "。\\nolinebreak[4]]")

          # Convert any zero-width spaces to latex equivalent
          lb.gsub!(/\u200B/, "\\hspace{0pt}")
        end

      end
    end
  end
end
