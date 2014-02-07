# -*- coding: utf-8 -*-

require 'kramdown/parser/kramdown'

module Kramdown
  module Parser

    class KramdownRepositext < Kramdown

      # Create a new Kramdown parser object with the given +options+.
      def initialize(source, options)
        super

        @block_parsers = [:blank_line, :atx_header, :horizontal_rule, :setext_header,
                          :block_extensions, :paragraph]
        @span_parsers =  [:emphasis, :span_extensions, :line_break,
                          :repositext_escaped_chars]
      end

      def parse #:nodoc:
        configure_parser
        parse_blocks(@root, adapt_source(source))
        update_tree(@root)
      end

      # original: ESCAPED_CHARS = /\\([\\.*_+`<>()\[\]{}#!:|"'\$=-])/
      REPOSITEXT_ESCAPED_CHARS = /\\([\\#*_{=@%-])/
      define_parser(:repositext_escaped_chars, REPOSITEXT_ESCAPED_CHARS, '\\\\', :parse_escaped_chars)

    end

  end
end
