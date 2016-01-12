class Repositext
  class Fix
    class NormalizeSubtitleMarkBeforeGapMarkPositions

      # Normalizes positions of subtitle_marks and gap_marks when they are
      # adjacent. subtitle_marks will always come first.
      # We make changes in place for better performance
      # (using `#gsub!` instead of `#gsub`).
      # Also moves both in front of leading eagle
      # @param [String] text
      # @param [String] filename
      # @return [Outcome]
      def self.fix(text, filename)
        text = text.dup
        # If line starts with eagle, followed by (space|gap_mark), and then a subtitle_mark,
        # move the single subtitle_mark to beginning of line.
        # NOTE: There may be multiple subtitle_marks. We only move one.
        text.gsub!(/^(\s*%?)(@)/, '\2\1') # Move subtitle_mark in front of eagle
        # If there is also a gap_mark after the eagle, move it to front of line
        # as well.
        text.gsub!(/(\s*@*)(%)/, '\2\1') # Move gap_mark in front of eagle

        text.gsub!(/%@/, '@%') # Do this last since the eagle transform may place them in the wrong order.

        Outcome.new(true, { contents: text }, [])
      end

    end
  end
end
