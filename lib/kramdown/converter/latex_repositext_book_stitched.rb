module Kramdown
  module Converter
    class LatexRepositextBookStitched < LatexRepositext

      include DocumentMixin

      def include_meta_info
        false
      end

      # Configure page settings. All values are in inches
      # @param key [Symbol]
      def page_settings(key)
        ps = {
          english_stitched: {
            paperwidth: 5.4375,
            paperheight: 8.375,
            inner: 0.4531,
            outer: 0.4844,
            top: 0.7733,
            bottom: 0.471,
            headsep: 0.1087,
            footskip: 0.351,
          },
          foreign_stitched: {
            paperwidth: 5.4375,
            paperheight: 8.375,
            inner: 0.625,
            outer: 0.6458,
            top: 0.76,
            bottom: 0.5,
            headsep: 0.172,
            footskip: 0.3515,
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
        @options[:is_primary_repo] ? -11.5 : -9.7
      end

    end
  end
end
