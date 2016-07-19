module Kramdown
  module Converter
    class LatexRepositextWeb < LatexRepositext

      include DocumentMixin

      def include_meta_info
        false
      end

      def magnification
        1000
      end

      # Configure page settings. All values are in inches
      # For web we use the regular finishing.
      # @param key [Symbol]
      def page_settings(key)
        {
          english_stitched: {
            paperwidth: '5.4375truein',
            paperheight: '8.375truein',
            inner: '0.4531truein',
            outer: '0.4844truein',
            top: '0.7733truein',
            bottom: '0.471truein',
            headsep: '0.1in', # We want this dimension to scale with geometry package \mag.
          },
          foreign_stitched: {
            paperwidth: '5.4375truein',
            paperheight: '8.375truein',
            inner: '0.625truein',
            outer: '0.6458truein',
            top: '0.76truein',
            bottom: '0.5truein',
            headsep: '0.1in', # We want this dimension to scale with geometry package \mag.
          },
        }.fetch(key)
      end
    end
  end
end
