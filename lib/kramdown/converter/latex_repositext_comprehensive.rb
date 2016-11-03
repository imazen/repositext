module Kramdown
  module Converter
    # Custom latex converter for PDF comprehensive format.
    class LatexRepositextComprehensive < LatexRepositext

      include DocumentMixin
      include RenderRecordMarksMixin

    end
  end
end
