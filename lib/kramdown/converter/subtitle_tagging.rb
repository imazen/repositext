module Kramdown
  module Converter
    # Converts kramdown element tree to subtitle tagging.
    class SubtitleTagging < Subtitle

    protected

      def gap_mark_output
        # gap_marks are rendered for subtitle_tagging output
        '%'
      end

      def subtitle_mark_output
        # subtitle_marks are removed for subtitle_tagging output
        ''
      end

      def add_subtitle_mark_to_beginning_of_first_paragraph(txt)
        # We don't add subtitle_marks in subtitle_tagging export, return txt as is
        txt
      end

    end
  end
end
