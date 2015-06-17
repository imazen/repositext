# -*- coding: utf-8 -*-

# Converts kramdown to HTML fragments.

module Kramdown
  module Converter
    class HtmlRepositext < Html

      # All ems are converted to spans
      def convert_em(el, indent)
        format_as_span_html(:span, el.attr, inner(el, indent))
      end

      def convert_gap_mark(el, indent)
        format_as_span_html(:span, { 'class' => 'gap_mark' }, '%')
      end

      def convert_record_mark(el, indent)
        # TBD
      end

      def convert_subtitle_mark(el, indent)
        format_as_span_html(:span, { 'class' => 'subtitle_mark' }, '@')
      end

    end
  end
end
