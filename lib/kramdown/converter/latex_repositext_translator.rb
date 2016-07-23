module Kramdown
  module Converter
    class LatexRepositextTranslator < LatexRepositext

      include DocumentMixin
      include RenderSubtitleAndGapMarksMixin

      # We ignore song_break behavior for translator PDFs so that translators
      # clearly see where the stanza boundaries are, and aren't confused by page
      # breaks inside a stanza. The tradeoff is that the spacing around songs
      # in translator PDFs may be excessive.
      def apply_song_break_class
        false
      end

    end
  end
end
