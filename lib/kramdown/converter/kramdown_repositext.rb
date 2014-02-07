require 'kramdown/converter/kramdown'

module Kramdown

  module Converter

    # Converts an element tree to the kramdown format.
    class KramdownRepositext < Kramdown


      # NOTE: We want to change which characters are being escaped when converting
      # to kramdown. And we don't want to monkey patch Kramdown::Converter::Kramdown.
      # So we redefine the regex and the method that uses it.
      # The #convert_text method didn't change, just the regex.
      # NOTE: this regex needs to be synchronized with the one in
      # Kramdown::Parser::KramdownRepositext
      # original: ESCAPED_CHAR_RE = /(\$\$|[\\*_`\[\]\{"'|])|^[ ]{0,3}(:)/
      ESCAPED_CHAR_RE_REPOSITEXT =  /(\$\$|[\\*_\[\]\{])|^[ ]{0,3}(:)/
      def convert_text(el, opts)
        if opts[:raw_text]
          el.value
        else
          el.value.gsub(/\A\n/) do
            opts[:prev] && opts[:prev].type == :br ? '' : "\n"
          end.gsub(/\s+/, ' ').gsub(ESCAPED_CHAR_RE_REPOSITEXT) { "\\#{$1 || $2}" }
        end
      end

    end

  end

end
