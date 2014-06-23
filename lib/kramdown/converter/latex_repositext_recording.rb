module Kramdown
  module Converter
    class LatexRepositextRecording < LatexRepositext

      include DocumentMixin
      include RenderSubtitleAndGapMarksMixin

    protected

      def latex_command_for_gap_mark
        '\\RtGapMarkWithNumber'
      end

    end
  end
end
