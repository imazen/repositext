module Kramdown
  module Converter
    class LatexRepositextBookRegular < LatexRepositext

      include DocumentMixin

      # Configure page settings. All values are in inches
      # @param key [Symbol]
      def page_settings(key)
        ps = {
          english_stitched: {
            paperwidth: 5.4375,
            paperheight: 8.375,
            inner: 0.4531,
            outer: 0.4844,
            top: 0.4705,
            bottom: 0.1202,
            headsep: 0.076,
            footskip: 0.3515,
          },
          foreign_stitched: {
            paperwidth: 5.4375,
            paperheight: 8.375,
            inner: 0.625,
            outer: 0.6458,
            top: 0.4229,
            bottom: 0.1375,
            headsep: 0.1,
          },
        }
        ps = ps[key]
        ps
      end

      def size_scale_factor
        1.0
      end

      def include_meta_info
        false
      end

    end
  end
end
