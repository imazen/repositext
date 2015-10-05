# -*- coding: utf-8 -*-

require 'kramdown/parser/kramdown'

module Kramdown
  module Parser
    class KramdownRepositext < Kramdown

      # Create a new Kramdown parser object with the given +options+.
      def initialize(source, options)
        super

        # NOTE: the order of parsers is important, don't change it!
        @block_parsers = [:blank_line, :atx_header, :horizontal_rule, :setext_header,
                          :block_extensions, :record_mark, :paragraph]
        @span_parsers =  [:emphasis, :subtitle_mark, :gap_mark,
                          :span_extensions, :html_entity, :line_break, :escaped_chars]
      end

      # @return[Array] array with [root, [warnings]]
      def parse #:nodoc:
        configure_parser
        parse_blocks(@root, adapt_source(source))
        update_tree(@root)
        # We comment out the following behavior from Kramdown::Parser::Kramdown
        # replace_abbreviations(@root)
        # @footnotes.each {|name,data| update_tree(data[:marker].last.value) if data[:marker]}
      end

      RECORD_MARK = /^\^\^\^\s*?(#{IAL_SPAN_START})?\s*?\n/

      # Parse the record mark at the current location
      def parse_record_mark
        start_line_number = @src.current_line_number
        if @src.scan(RECORD_MARK)
          @tree = el = new_block_el(:record_mark, nil, nil, category: :block, location: start_line_number)
          parse_attribute_list(@src[2], el.options[:ial] ||= Utils::OrderedHash.new) if @src[1]
          @root.children << el
          true
        else
          false
        end
      end
      define_parser(:record_mark, /^\^\^\^/)


      SUBTITLE_MARK = /@/

      # Parse subtitle mark at current location.
      def parse_subtitle_mark
        start_line_number = @src.current_line_number
        @src.pos += @src.matched_size
        @tree.children << Element.new(:subtitle_mark, nil, nil, :category => :span, location: start_line_number)
      end
      define_parser(:subtitle_mark, SUBTITLE_MARK, SUBTITLE_MARK)


      # TODO: We want to be able to escape percent signs with a leading
      # backslash '\'. This is not trivial as we need to modify Kramdown's
      # :escaped_chars parser. It uses a previously defined constant
      # ESCAPED_CHARS, and kramdown may not allow redefinition of parsers...
      # (double check latest claim).
      GAP_MARK = /%/

      # Parse gap mark at current location.
      def parse_gap_mark
        start_line_number = @src.current_line_number
        @src.pos += @src.matched_size
        @tree.children << Element.new(:gap_mark, nil, nil, :category => :span, location: start_line_number)
      end
      define_parser(:gap_mark, GAP_MARK, GAP_MARK)

    end
  end
end
