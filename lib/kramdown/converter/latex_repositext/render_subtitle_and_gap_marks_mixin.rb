module Kramdown
  module Converter
    class LatexRepositext

      # Include this module in latex converters that render subtitle_marks and gap_marks
      module RenderSubtitleAndGapMarksMixin

        def convert_gap_mark(el, opts)
          @options[:disable_gap_mark] ? "" : tmp_gap_mark_complete
        end

        def convert_subtitle_mark(el, opts)
          @options[:disable_subtitle_mark] ? "" : '' # "<<<subtitle-mark>>>"
        end

      protected

        def latex_environment_for_translator_omit
          ["\\begin{RtOmit}\n", "\n\\end{RtOmit}"]
        end

      end
    end
  end
end
