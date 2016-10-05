module Kramdown
  module Converter
    class LatexRepositext
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
          chars_to_skip = [
            Repositext::D_QUOTE_OPEN,
            Repositext::EM_DASH,
            Repositext::S_QUOTE_OPEN,
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
                  #{ Repositext::ELIPSIS } # elipsis
                  (?!#{ Repositext::ELIPSIS }) # not followed by another elipsis so we exclude chinese double elipsis
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
                #{ Repositext::ELIPSIS }? # optional elipsis
                [[:alpha:][:digit:]’\-\?,]* # words and some punctuation
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
              Repositext::APOSTROPHE,
              Repositext::D_QUOTE_OPEN,
              Repositext::S_QUOTE_OPEN,
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
                 # followed by eagle
              /x,
              '\1' # Reverse order
            )
            # Convert tmp_gap_mark_number to latex command
            lb.gsub!(gap_mark_number_regex, "\\RtGapMarkNumber")
          end
          # Make sure no tmp_gap_marks are left
          if(ltgm = lb.match(/.{0,10}#{ Regexp.escape(tmp_gap_mark_text) }.{0,10}/))
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
            "\\RtFirstEagle " + '\1' # we use an environment for first eagle
          )
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
        end

        # Removes space after paragraph number to avoid fluctuations in indent.
        # @param lb [String] latex body, will be modified in place.
        def remove_space_after_paragraph_numbers!(lb)
          lb.gsub!(/(\\RtParagraphNumber\{[^\}]+\})\s*/, '\1')
        end

        # Determines where line breaks are allowed to happen.
        # @param lb [String] latex body, will be modified in place.
        def set_line_break_positions!(lb)
          # Don't break lines between double open quote and apostrophe (via ~)
          lb.gsub!(
            "#{ Repositext::D_QUOTE_OPEN } #{ Repositext::APOSTROPHE }",
            "#{ Repositext::D_QUOTE_OPEN }~#{ Repositext::APOSTROPHE }"
          )

          # Insert zero-width space after all elipses, emdashes, and hyphens.
          # This gives latex the option to break a line after these characters.
          # \hspace{0pt} is the latex equivalent of zero-width space (&#x200B;)
          line_breakable_chars = Regexp.escape(
            [Repositext::ELIPSIS, Repositext::EM_DASH, '-'].join
          )
          # Exceptions: Don't insert zero-width space if followed by no-break characters:
          no_break_following_chars = Regexp.escape(
            [Repositext::S_QUOTE_CLOSE, Repositext::D_QUOTE_CLOSE, ')?,!'].join
          )
          # We only want to allow linebreak _after_ line_breakable_chars but not _before_.
          # We insert a \\nolinebreak to prevent linebreaks _before_.
          # Excpetions: no_break_following_chars or ed_and_trn_abbreviations
          lb.gsub!(
            /
              (
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
            "\\nolinebreak[4]" + '\1' + "\\hspace{0pt}"
          )

          # We don't allow linebreaks _before_ or _after_ an emdash when followed
          # by some abbreviations.
          lb.gsub!(
            /
              #{ Repositext::EM_DASH }
              (
                #{ options[:ed_and_trn_abbreviations] }
              )
            /ix,
            "\\nolinebreak[4]" + Repositext::EM_DASH + "\\nolinebreak[4]" + '\1'
          )

          # We don't allow linebreaks before certain numbers
          lb.gsub!(/(?<=[a-z])\s(?=\d)/, "~")

          # Convert any zero-width spaces to latex equivelant
          lb.gsub!(/\u200B/, "\\hspace{0pt}")
        end

      end
    end
  end
end
