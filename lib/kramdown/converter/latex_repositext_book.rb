module Kramdown
  module Converter
    # Custom latex converter for PDF book format.
    class LatexRepositextBook < LatexRepositext

      include DocumentMixin

      def include_meta_info
        false
      end

      def magnification
        1000
      end

      # Configure page settings. All values are in inches
      # @param key [Symbol]
      def page_settings(key)
        {
          english_bound: {
            paperwidth: '5.375truein',
            paperheight: '8.375truein',
            inner: '0.6875truein',
            outer: '0.5208truein',
            top: '0.7733truein',
            bottom: '0.471truein',
            headsep: '0.1106in', # We want this dimension to scale with geometry package \mag.
            footskip: '0.351in', # We want this dimension to scale with geometry package \mag.
          },
          english_stitched: {
            paperwidth: '5.4375truein',
            paperheight: '8.375truein',
            inner: '0.4531truein',
            outer: '0.4844truein',
            top: '0.7733truein',
            bottom: '0.471truein',
            headsep: '0.1106in', # We want this dimension to scale with geometry package \mag.
            footskip: '0.351in', # We want this dimension to scale with geometry package \mag.
          },
          foreign_bound: {
            paperwidth: '5.375truein',
            paperheight: '8.375truein',
            inner: '0.6875truein',
            outer: '0.5208truein',
            top: '0.76truein',
            bottom: '0.5truein',
            headsep: '0.172in', # We want this dimension to scale with geometry package \mag.
          },
          foreign_stitched: {
            paperwidth: '5.4375truein',
            paperheight: '8.375truein',
            inner: '0.625truein',
            outer: '0.6458truein',
            top: '0.76truein',
            bottom: '0.5truein',
            headsep: '0.172in', # We want this dimension to scale with geometry package \mag.
          },
        }.fetch(key)
      end
    end
  end
end
