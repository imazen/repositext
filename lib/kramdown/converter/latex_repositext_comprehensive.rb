module Kramdown
  module Converter
    class LatexRepositextComprehensive < LatexRepositext

      include DocumentMixin
      include RenderRecordMarksMixin

    end
  end
end
