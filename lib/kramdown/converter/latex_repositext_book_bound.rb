module Kramdown
  module Converter
    class LatexRepositextBookBound < LatexRepositext

      include DocumentMixin

      def include_meta_info
        false
      end

      # Configure page settings. All values are in inches
      # @param key [Symbol]
      def page_settings(key)
        ps = {
          english_bound: {
            paperwidth: 5.375,
            paperheight: 8.375,
            inner: 0.6875,
            outer: 0.5208,
            top: 0.7733,
            bottom: 0.471,
            headsep: 0.1,
          },
          foreign_bound: {
            paperwidth: 5.375,
            paperheight: 8.375,
            inner: 0.6875,
            outer: 0.5208,
            top: 0.76,
            bottom: 0.5,
            headsep: 0.1,
          },
        }
        ps = ps[key]
        ps
      end

      def size_scale_factor
        1.0
      end

      # Override for book sizes
      def title_vspace
        -9.7
      end

    end
  end
end
