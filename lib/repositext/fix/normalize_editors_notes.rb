class Repositext
  class Fix
    class NormalizeEditorsNotes

      # Normalizes instances of `—Ed.]`. Run this before convert_folio_typographical_chars
      # We make changes in place for better performance
      # (using `#gsub!` instead of `#gsub`).
      # @param[String] text
      # @param[String] filename
      # @param[String, optional] separator_char what character to use as dash.
      #                          Defaults to emdash.
      # @return[Outcome]
      def self.fix(text, filename, separator_char='—')
        text = text.dup
        text.gsub!(/[—\-]* ?Ed\.?\]/, %(#{ separator_char }Ed.]))
        # Handle a case like this where an asterisk is in the wrong spot: `—*Ed` => `—*—Ed`
        # Drop the first emdash or double hyphen
        text.gsub!(
          /(—|\-\-)(\*+)(?=#{ separator_char }Ed\.\])/,
          '\2'
        )
        Outcome.new(true, { contents: text }, [])
      end

    end
  end
end
