class Repositext
  class Fix
    # Moves gap_marks (%) to the outside of
    # * asterisks
    # * quotes (primary or secondary)
    # * parentheses
    # * brackets
    # Those characters may be nested, move % all the way out if those characters
    # are directly adjacent.
    # If % directly follows an elipsis, move to the front of the ellipsis
    # (unless where elipsis and % are between two words like so: word…%word)
    class AdjustGapMarkPositions

      # @param text [String]
      # @param filename [String]
      # @param language [Language]
      # @return [Outcome]
      def self.fix(text, filename, language)
        new_at = text.dup
        move_gap_marks_to_beginning_of_words!(new_at, language)
        new_at = fix_standard_chars(new_at, language) # can't do in-place
        new_at = fix_chinese_chars(new_at, language) # can't do in-place
        new_at = fix_elipsis(new_at, language) # do this after fixing standard chars, can't do in-place
        # run again at the end to fix any in-word gap_marks that may have been
        # created by the previous steps.
        move_gap_marks_to_beginning_of_words!(new_at, language)
        Outcome.new(true, { contents: new_at }, [])
      end

      # Moves a gap mark inside or at the end of a word to the beginning of the
      # word. Replaces any gap_marks that are already at the beginning of the word.
      # @param text [String]
      # @param language [Language]
      def self.move_gap_marks_to_beginning_of_words!(text, language)
        text.gsub!(/%?\b([[:alpha:]&&[^\p{Han}]]+)%/, '%\1')
      end

      # Fixes gap_marks in invalid positions after the standard characters
      # @param text [String]
      # @param language [Language]
      def self.fix_standard_chars(text, language)
        old_at = text.dup
        new_at = ''
        # asterisk, double open quote, single open quote, opening parens,
        # opening bracket, opening chinese parens, opening chinese quote
        standard_chars = "*([（《#{ language.chars[:d_quote_open] }#{ language.chars[:s_quote_open] }"
        standard_chars_regex = /[#{ Regexp.escape(standard_chars) }]+/
        standard_chars_and_gap_mark_regex = /#{ standard_chars_regex }\%/

        s = StringScanner.new(old_at)
        while !s.eos? do
          # Match up to, excluding the preceding chars and the gap_mark at invalid position
          contents = s.scan(/.*?(?=#{ standard_chars_and_gap_mark_regex })/m)
          if contents
            # Found a gap_mark at invalid position
            new_at << contents
            # capture preceding chars and gap_mark
            contents = s.scan(standard_chars_and_gap_mark_regex)
            if contents
              # move gap_mark to the front, add all to new_at
              new_at << "%#{ contents.gsub('%', '') }"
            else
              raise "Couldn't capture gap_mark in invalid position"
            end
          else
            # No gap_mark at invalid position found
            new_at << s.rest
            s.terminate
          end
        end
        new_at
      end

      # Fixes gap_marks for chinese docs
      # @param text [String]
      # @param language [Language]
      def self.fix_chinese_chars(text, language)
        new_at = text.dup
        # Move gap_marks to after single closing quotes/apostrophes (%'c => '%c)
        # TODO: update this to use Language.chars[:apostrophe] and [:s_quote_close] instead of Repositext constant
        chars_regex = "[#{ Regexp.escape([language.chars[:apostrophe], language.chars[:s_quote_close]].uniq.join) }]"
        new_at.gsub!(/\%(#{ chars_regex })(?=\p{Han})/, '\1%')
        new_at
      end

      # Fixes gap_marks in invalid positions after elipsis
      # @param text [String]
      # @param language [Language]
      def self.fix_elipsis(text, language)
        old_at = text.dup
        new_at = ''
        elipsis_regex = /#{ language.chars[:elipsis] }+/
        elipsis_and_gap_mark_regex = /#{ elipsis_regex }\%/

        s = StringScanner.new(old_at)
        while !s.eos? do
          # Match up to, excluding the preceding chars and the gap_mark at invalid position
          # move to front of elipsis only if preceded by space or colon
          contents = s.scan(/(.*?[[:space:]\:])?(?=#{ elipsis_and_gap_mark_regex })/m)
          if contents
            # Found a gap_mark at invalid position
            new_at << contents
            # capture preceding chars and gap_mark
            contents = s.scan(elipsis_and_gap_mark_regex)
            if contents
              # move gap_mark to the front, add all to new_at
              new_at << "%#{ contents.gsub('%', '') }"
            else
              raise "Couldn't capture gap_mark in invalid position"
            end
          else
            # No gap_mark at invalid position found
            new_at << s.rest
            s.terminate
          end
        end
        new_at
      end

    end
  end
end
