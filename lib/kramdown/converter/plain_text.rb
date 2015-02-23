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
        case el.type
        when :a
          # nothing to do
        when :blank
          # nothing to do
        when :em
          # nothing to do
        when :entity
          # Decode whitelisted entities
          @plain_text << Repositext::Utils::EntityEncoder.decode(el.options[:original])
        when :gap_mark
          # nothing to do
        when :header
          # add a new line for each header
          @plain_text << "\n"
        when :hr
          # put 7 asterisks on new line.
          @plain_text << "\n* * * * * * *"
        when :p
          # add a new line for each paragraph
          @plain_text << "\n"
        when :record_mark
          # nothing to do
        when :root
          # nothing to do
        when :strong
          # nothing to do
        when :subtitle_mark
          # nothing to do
        when :text
          # capture value of all :text elements
          @plain_text << el.value
        else
          raise "Handle this element: #{ el.inspect }"
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
