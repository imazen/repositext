class Repositext
  class Fix
    class NormalizeSubtitleMarkBeforeGapMarkPositions

      # Normalizes positions of subtitle_marks and gap_marks when they are
      # adjacent. subtitle_marks will always come first.
      # We make changes in place for better performance
      # (using `#gsub!` instead of `#gsub`).
      # @param[String] text
      # @param[String] filename
      # @return[Outcome]
      def self.fix(text, filename)
        text = text.dup
        text.gsub!(/%@/, '@%')
        Outcome.new(true, { contents: text }, [])
      end

    end
  end
end
