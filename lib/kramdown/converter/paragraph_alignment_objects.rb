# -*- coding: utf-8 -*-
module Kramdown
  module Converter

    # Converts kramdown tree to block level objects that can be used for
    # paragraph alignment (headers, paragraphs with and without numbers).
    # Returns an array of Block elements
    class ParagraphAlignmentObjects < KramdownRepositext

      # Instantiate a converter
      # @param [Kramdown::Element] root
      # @param [Hash{Symbol => Object}] options
      def initialize(root, options)
        super
        @block_elements = [] # collector for block level objects
        @current_block = nil
        @para_counter = 0
        @subtitle_mark_counter = 0
      end

      # Override any element specific convert methods that require overrides:

      def convert_em(el, opts)
        if el.has_class?('pn')
          # extract paragraph number
          text_node = el.children.detect { |e| :text == el.type }
          @current_block.paragraph_number = text_node.value  if text_node
        end
        super
      end

      def convert_header(el, opts)
        @current_block = ParagraphAlignmentObjects::BlockElement.new(
          name: 'Header',
          type: :header,
          contents: '',
          ke_attrs: el.attr,
          subtitle_mark_indexes: [],
          key: el.options[:level]
        )
        @current_block.contents = super # call super after @current_block has been assigned
        @block_elements << @current_block
        ''
      end

      def convert_hr(el, opts)
        @current_block = ParagraphAlignmentObjects::BlockElement.new(
          name: 'HR',
          type: :hr,
          contents: '',
          ke_attrs: el.attr,
          subtitle_mark_indexes: [],
        )
        @current_block.contents = super # call super after @current_block has been assigned
        @block_elements << @current_block
        ''
      end

      def convert_p(el, opts)
        @current_block = ParagraphAlignmentObjects::BlockElement.new(
          name: (@para_counter += 1).to_s,
          type: :p,
          contents: '',
          ke_attrs: el.attr,
          subtitle_mark_indexes: [],
        )
        @current_block.contents = super # call super after @current_block has been assigned
        # The kramdown :p converter escapes the period in "1. word" to "1\\. word".
        # Possibly to indicate that this is not part of an ordered list.
        # We have to remove that since we're not working with proper kramdown,
        # but with plain text contents in this class.
        @current_block.contents.sub!(/\A@*(\d+)\\(?=\.)/, '\1')

        if(m = @current_block.contents.match(/\A@*(\d+)\s/))
          # TODO: old regex from TreeExtractor checked for absence of hyphen. Investigate: key: pn !~ /\A-/ ? pn : nil
          # starts with digit, use paragraph number as key
          @current_block.key = m[1].to_i
        end

        @block_elements << @current_block
        ''
      end

      def convert_record_mark(el, opts)
        # Nothing to do, ignore
        ''
      end

      def convert_subtitle_mark(el, opts)
        # increment subtitle_mark_counter and record it on para
        @subtitle_mark_counter += 1
        @current_block.subtitle_mark_indexes << @subtitle_mark_counter
        super
      end

      def convert_root(el, opts)
        inner(el, opts) # convert child elements
        return @block_elements
      end

    end
  end
end
