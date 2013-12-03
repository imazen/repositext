# -*- coding: utf-8 -*-

# Converts tree to plain text. Removes all formatting and attributes.
# This converter can be used, e.g., to get a header's text contents.
module Kramdown
  module Converter
    class PlainText < Base

      # Instantiate a PlainText converter
      # @param[Kramdown::Element] root
      # @param[Hash] options
      def initialize(root, options)
        super
        @plain_text = '' # collector for plain text string
      end

      # Extracts plain text from tree
      # @param[Kramdown::Element] el
      # @return[String] the plain text
      def convert(el)
        if :text == el.type
          # capture value of all :text elements
          @plain_text << el.value
        end
        if :block == Element.category(el)
          # add a new line for each :block element
          @plain_text << "\n"
        end
        # walk the tree
        el.children.each { |e| convert(e) }
        if :root == el.type
          # return @plain_text for :root element
          return @plain_text.strip
        end
      end

    end
  end
end
