module Kramdown

  module Converter

    # Converts an element tree to the kramdown format.
    class KramdownRepositext < Kramdown


      # NOTE: We want to change which characters are being escaped when converting
      # to kramdown. And we don't want to monkey patch Kramdown::Converter::Kramdown.
      # So we redefine the regex and the method that uses it.
      # The #convert_text method didn't change, just the regex.
      # original: ESCAPED_CHAR_RE = /(\$\$|[\\*_`\[\]\{"'|])|^[ ]{0,3}(:)/
      # Differences of new regex:
      # * don't escape '`', '[', ']', '"', '''
      # * don't escape a line's leading colon ':'. This is used for definition
      #   lists (which are not supported yet by repositext).
      #   The problem is that the original regex looks at a colon at the beginning
      #   of a line. However this kramdown: '*this*: that' will have a text element
      #   in the parse tree where the text starts with a colon (after the em).
      #   So converting this to kramdown would escape the colon.
      #   If we ever decide to support definition lists, we may have to revisit
      #   this and look at el's previous sibling to decide if we want to escape
      #   the colon or not.
      ESCAPED_CHAR_RE_REPOSITEXT =  /(\$\$|[\\*_\{])/
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
