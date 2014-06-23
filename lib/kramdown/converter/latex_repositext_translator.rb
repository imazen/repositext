module Kramdown
  module Converter
    class LatexRepositextTranslator < LatexRepositext

      include DocumentMixin
      include RenderSubtitleAndGapMarksMixin

    end
  end
end
