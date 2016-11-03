module Kramdown
  module Converter
    # Custom latex converter for PDF plain format.
    class LatexRepositextPlain < LatexRepositext

      include DocumentMixin

    end
  end
end
