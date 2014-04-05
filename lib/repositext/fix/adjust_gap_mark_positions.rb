class Repositext
  class Fix
    class AdjustGapMarkPositions

      # Move gap_marks (%) to the outside of
      # * asterisks
      # * quotes (primary or secondary)
      # * parentheses
      # * brackets
      # Those characters may be nested, move % all the way out if those characters
      # are directly adjacent.
      # If % directly follows an elipsis, move to the front of the ellipsis
      # (unless where elipsis and % are between two words like so: word…%word)
      # @param[String] text
      # @return[Outcome]
      def self.fix(text)
        new_at = fix_two_gap_marks_in_one_word(text)
        new_at = fix_standard_chars(new_at)
        new_at = fix_elipsis(new_at) # do this after fixing standard chars
        Outcome.new(true, { contents: new_at }, [])
      end

      # Removes second gap mark inside a word if word is already preceded by a gap_mark
      def self.fix_two_gap_marks_in_one_word(text)
        text.gsub(/(%)([[:alpha:]]+)%([[:alpha:]]+)/, '%\2\3')
      end

      # Fixes gap_marks in invalid positions after the standard characters
      def self.fix_standard_chars(text)
        old_at = text.dup
        new_at = ''
        standard_chars_regex = /[\*\"\'\(\[]+/
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

      # Fixes gap_marks in invalid positions after elipsis
      def self.fix_elipsis(text)
        old_at = text.dup
        new_at = ''
        elipsis_regex = /…+/
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
