module Kramdown
  module Converter
    class LatexRepositextRecording < LatexRepositext

      include DocumentMixin
      include RenderSubtitleAndGapMarksMixin

    protected

      def tmp_gap_mark_number
        "<<<gap-mark-number>>>"
      end

    end
  end
end
