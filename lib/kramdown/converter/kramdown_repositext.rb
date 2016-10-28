module Kramdown
  module Converter
    # Converts a kramdown element tree to a string of serialized kramdown text.
    class KramdownRepositext < Kramdown

      # copied from original converter because the :record_mark element needs to be handled specially
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert(el, opts = {:indent => 0})
        res = send("convert_#{el.type}", el, opts)
        if ![:html_element, :li, :dd, :td, :record_mark].include?(el.type) && (ial = ial_for_element(el))
          res << ial
          res << "\n\n" if Element.category(el) == :block
        elsif [:ul, :dl, :ol, :codeblock].include?(el.type) && opts[:next] &&
            ([el.type, :codeblock].include?(opts[:next].type) ||
             (opts[:next].type == :blank && opts[:nnext] && [el.type, :codeblock].include?(opts[:nnext].type)))
          res << "^\n\n"
        elsif Element.category(el) == :block &&
            ![:li, :dd, :dt, :td, :th, :tr, :thead, :tbody, :tfoot, :blank].include?(el.type) &&
            (el.type != :html_element || @stack.last.type != :html_element) &&
            (el.type != :p || !el.options[:transparent])
          res << "\n"
        end
        res
      end

      # Override Kramdown's method which encodes entities as decimal. We want hex.
      # @param el [Kramdown::Element]
      # @param indent [Integer]
      def convert_entity(el, indent)
        sprintf('&#x%04X;', el.value.code_point)
      end

      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_gap_mark(el, opts)
        @options[:disable_gap_mark] ? "" : "%"
      end

      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_record_mark(el, opts)
        if @options[:disable_record_mark]
          inner(el, opts)
        else
          ial = ial_for_element(el)
          "^^^#{ial ? " #{ial}" : ""}\n\n#{inner(el, opts)}"
        end
      end

      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_subtitle_mark(el, opts)
        @options[:disable_subtitle_mark] ? "" : "@"
      end

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
