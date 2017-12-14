class Repositext
  class Process
    class Fix
      # Moves subtitle_marks (@) to the outside of
      # * asterisks
      # * quotes (primary or secondary)
      # * parentheses
      # * brackets
      # * IALs
      # Those characters may be nested, move @ all the way out if those characters
      # are directly adjacent.
      class AdjustSubtitleMarkPositions

        # @param text [String]
        # @param language [Language]
        # @return [Outcome]
        def self.fix(text, language)
          new_txt = text.dup
          fix_positions!(new_txt, language)
          Outcome.new(true, new_txt, [])
        end

        # TODO: Review Fix::AdjustGapMarkPositions for further adjustments we
        # could make here.
        # TODO: Refactor other places in code that adjust subtitle_mark positions
        # to use this Process.
        def self.fix_positions!(txt, language)
          # Move subtitle marks to beginning of words
          # "word.@ word" => "word. @word"
          txt.gsub!(/@ (?=\S)/, ' @')
          # Move spaces inside subtitle_marker sequences to beginning of the
          # sequence "word.@@@@@ @word" => "word. @@@@@@word"
          txt.gsub!(/(@+) (@+)/, ' \1\2')
          # Move subtitle_marks to the outside of closing quote marks
          # "word.@” word" => "word.” @word"
          txt.gsub!(/@” (?=\w)/, '” @')
          # Move subtitle_marks to the outside of opening parens
          # "(@word)" => "@(word)"
          txt.gsub!(/\(@/, '@(')
          # Move subtitle_marks to the outside of closing parens
          # "word.@) word" => "word.) @word"
          txt.gsub!(/@\) (?=\w)/, ') @')
        end

      end
    end
  end
end
