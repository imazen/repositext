# -*- coding: utf-8 -*-

require 'kramdown/parser'

module Kramdown
  module Parser

    class Repositext < Kramdown

      # Create a new Kramdown parser object with the given +options+.
      def initialize(source, options)
        super

        @block_parsers = [:blank_line, :atx_header, :horizontal_rule, :setext_header,
                          :block_extensions, :document_divider, :paragraph]
        @span_parsers =  [:emphasis, :word_synchro_marker, :line_synchro_marker,
                          :span_extensions]
      end

      def parse #:nodoc:
        configure_parser
        str = adapt_source(source)
        if str !~ /\A\s*#{DOCUMENT_DIVIDER}/
          str = "^^^\n#{ str }"
        end
        parse_blocks(@root.children.last, str)
        update_tree(@root)
      end



      DOCUMENT_DIVIDER = /^\^\^\^\s*?(#{IAL_SPAN_START})?\s*?\n/

      # Parse the document divider at the current location
      def parse_document_divider
        if @src.scan(DOCUMENT_DIVIDER)
          @tree = el = new_block_el(:subdoc, nil, nil, :category => :block)
          parse_attribute_list(@src[2], el.options[:ial] ||= Utils::OrderedHash.new) if @src[1]
          @root.children << el
          true
        else
          false
        end
      end
      define_parser(:document_divider, /^\^\^\^/)


      WORD_SYNCHRO_MARKER = /@/

      # Parse word synchronization marker at current location.
      def parse_word_synchro_marker
        @src.pos += @src.matched_size
        @tree.children << Element.new(:word_synchro_marker, nil, nil, :category => :span)
      end
      define_parser(:word_synchro_marker, WORD_SYNCHRO_MARKER, WORD_SYNCHRO_MARKER)


      LINE_SYNCHRO_MARKER = /%/

      # Parse line synchronization marker at current location.
      def parse_line_synchro_marker
        @src.pos += @src.matched_size
        @tree.children << Element.new(:line_synchro_marker, nil, nil, :category => :span)
      end
      define_parser(:line_synchro_marker, LINE_SYNCHRO_MARKER, LINE_SYNCHRO_MARKER)

    end

  end
end
