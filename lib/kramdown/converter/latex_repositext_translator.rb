module Kramdown
  module Converter
    class LatexRepositextTranslator < LatexRepositext

      include DocumentMixin
      include RenderRecordMarksMixin
      include RenderSubtitleAndGapMarksMixin

    end
  end
end
