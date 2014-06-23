module Kramdown
  module Converter
    class LatexRepositextWeb < LatexRepositext

      include DocumentMixin

      def include_meta_info
        false
      end

    end
  end
end
