module Kramdown
  module Converter
    # Custom latex converter for PDF translator format.
    class LatexRepositextTranslator < LatexRepositext

      include DocumentMixin
      include RenderSubtitleAndGapMarksMixin

      # We ignore song_break behavior for English translator PDFs so that
      # translators clearly see where the stanza boundaries are when translating,
      # and aren't confused by page breaks inside a stanza. The tradeoff is that
      # the spacing around songs in English translator PDFs may be excessive.
      def apply_song_break_class
        @options[:is_primary_repo] ? false : true
      end

    end
  end
end
