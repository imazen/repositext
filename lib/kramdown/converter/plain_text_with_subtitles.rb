module Kramdown
  module Converter
    # Converts kramdown element tree to plain text with subtitles.
    class PlainTextWithSubtitles < PlainText

      # Return true to include line breaks for `.line_break` IAL classes.
      # @param options [Hash]
      def self.handle_line_break_class?(options)
        false
      end

      # Return false to ignore id
      # @param options [Hash]
      def self.include_id_elements?(options)
        false
      end

      # Override this in subclass to include subtitles in plain_text export
      # @param options [Hash]
      # @return [Array<String, Nil>, Nil] tuple of before and after text or nil if nothing to do
      def self.subtitle_mark_output(options)
        # subtitle_marks are rendered for subtitle output
        ['@', nil]
      end

    end
  end
end
