class Repositext
  class Fix
    class NormalizeSubtitleMarkBeforeGapMarkPositions

      # Normalizes positions of subtitle_marks and gap_marks when they are
      # adjacent. subtitle_marks will always come first.
      # We make changes in place for better performance
      # (using `#gsub!` instead of `#gsub`).
      # Also moves both in front of leading eagle
      # @param[String] text
      # @param[String] filename
      # @return[Outcome]
      def self.fix(text, filename)
        text = text.dup
        text.gsub!(/%@/, '@%')
        text.gsub!(/(\s*)(@?%?)/, '\2\1') # Move both marks in front of eagle

        Outcome.new(true, { contents: text }, [])
      end

    end
  end
end
