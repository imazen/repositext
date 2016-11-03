module Kramdown
  module Converter
    class LatexRepositext
      # Include this module in latex converters that render subtitle_marks and gap_marks
      module RenderSubtitleAndGapMarksMixin

        # @param el [Kramdown::Element]
        # @param opts [Hash{Symbol => Object}]
        # @return [String]
        def convert_gap_mark(el, opts)
          @options[:disable_gap_mark] ? "" : tmp_gap_mark_complete
        end

        # @param el [Kramdown::Element]
        # @param opts [Hash{Symbol => Object}]
        # @return [String]
        def convert_subtitle_mark(el, opts)
          @options[:disable_subtitle_mark] ? "" : '' # "<<<subtitle-mark>>>"
        end

      protected

        # @return [String]
        def latex_environment_for_translator_omit
          ["\\begin{RtOmit}\n", "\n\\end{RtOmit}"]
        end

      end
    end
  end
end
