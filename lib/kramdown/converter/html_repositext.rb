module Kramdown
  module Converter
    # Converts kramdown element tree to HTML fragments.
    class HtmlRepositext < Html

      # All ems are converted to spans
      # @param el [Kramdown::Element]
      # @param indent [Integer]
      def convert_em(el, indent)
        format_as_span_html(:span, el.attr, inner(el, indent))
      end

      # @param el [Kramdown::Element]
      # @param indent [Integer]
      def convert_gap_mark(el, indent)
        format_as_span_html(:span, { 'class' => 'gap_mark' }, '%')
      end

      # @param el [Kramdown::Element]
      # @param indent [Integer]
      def convert_record_mark(el, indent)
        # TBD
      end

      # @param el [Kramdown::Element]
      # @param indent [Integer]
      def convert_subtitle_mark(el, indent)
        format_as_span_html(:span, { 'class' => 'subtitle_mark' }, '@')
      end

    end
  end
end
