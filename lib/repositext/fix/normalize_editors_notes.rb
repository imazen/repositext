class Repositext
  class Fix
    class NormalizeEditorsNotes

      # Normalizes instances of `—Ed.]`. Run this before convert_folio_typographical_chars
      # We make changes in place for better performance
      # (using `#gsub!` instead of `#gsub`).
      # @param[String] text
      # @param[String] filename
      # @return[Outcome]
      def self.fix(text, filename)
        text = text.dup
        text.gsub!(/[—\-]* ?Ed\.?\]/, %(—Ed.]))
        Outcome.new(true, { contents: text }, [])
      end

    end
  end
end
