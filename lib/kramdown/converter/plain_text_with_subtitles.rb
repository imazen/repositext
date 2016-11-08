module Kramdown
  module Converter
    # Converts kramdown element tree to plain text with subtitles.
    class PlainTextWithSubtitles < PlainText

      # Override this in subclass to include subtitles in plain_text export
      # @return [Array<String, Nil>, Nil] tuple of before and after text or nil if nothing to do
      def self.subtitle_mark_output
        # subtitle_marks are rendered for subtitle output
        ['@', nil]
      end

    end
  end
end
