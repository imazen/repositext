module Kramdown
  module Converter
    # Converts kramdown element tree to plain text. Removes all formatting and
    # attributes. This converter can be used, e.g., to get a header's text contents.
    class PlainText < Base

      # Instantiate a PlainText converter
      # @param [Kramdown::Element] root
      # @param [Hash{Symbol => Object}] options
      def initialize(root, options)
        super
        @plain_text = '' # collector for plain text string
        @convert_smcaps_to_upper_case = options[:convert_smcaps_to_upper_case]
      end

      # Extract conversion dispatcher into class method so that we can use it
      # from other places (e.g., when patching Kramdown::Element#to_plain_text)
      # @param el [Kramdown::Element]
      # @param convert_to_upper_case [Boolean, optional], defaults to false.
      # @return [Array<String>, Nil] tuple of before and after text or nil if nothing to do
      def self.convert_el(el, convert_to_upper_case=false)
        case el.type
        when :a
          # nothing to do
        when :blank
          # nothing to do
        when :em
          if el.has_class?('line_break')
            # line_break, capture newline, ignore all children
            el.children = []
            ["\n", nil]
          else
            # nothing to do
          end
        when :entity
          # Decode whitelisted entities
          [Repositext::Utils::EntityEncoder.decode(el.options[:original]), nil]
        when :gap_mark
          # nothing to do
        when :header
          # add a new line for each header
          [nil, "\n"]
        when :hr
          # put 7 asterisks on new line.
          ["* * * * * * *\n", nil]
        when :p
          # add a new line for each paragraph
          [nil, "\n"]
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
          if convert_to_upper_case
            [el.value.unicode_upcase, nil]
          else
            [el.value, nil]
          end
        else
          raise "Handle this element: #{ el.inspect }"
        end
      end

      # Extracts plain text from tree
      # @param [Kramdown::Element] el
      # @param options [Hash{Symbol => Object}]
      # @return [String] the plain text
      def convert(el, options = {})
        options = {
          convert_to_upper_case: false
        }.merge(options)

        # Detect em.smcaps and convert any contained text to upper case
        if @convert_smcaps_to_upper_case && :em == el.type && el.has_class?('smcaps')
          options[:convert_to_upper_case] = true
        end

        # Convert el to plain_text
        before, after = self.class.convert_el(el, options[:convert_to_upper_case])

        # Record `before` segment
        @plain_text << before  if before

        # walk the tree
        el.children.each { |e| convert(e, options) }

        # Record `after` segment
        @plain_text << after  if after

        # Return @plain_text after finishing :root el
        if :root == el.type
          # return @plain_text for :root element
          return @plain_text.strip
        end
      end

    end
  end
end
