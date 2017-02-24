module Kramdown
  module Converter
    # Converts kramdown element tree to plain text. Removes all formatting and
    # attributes. This converter can be used, e.g., to get a header's text contents.
    class PlainText < Base

      # Instantiate a PlainText converter
      # @param [Kramdown::Element] root
      # @param [Hash{Symbol => Object}] options
      #   Available options:
      #   * :convert_smcaps_to_upper_case - whether to convert text in *<text>*{: .smcaps} to upper case
      #   These options will be assigned to @options and are available in instance
      #   methods.
      def initialize(root, options)
        super
        @plain_text = '' # collector for plain text string
      end

      # Extract conversion dispatcher into class method so that we can use it
      # from other places (e.g., when patching Kramdown::Element#to_plain_text)
      # @param el [Kramdown::Element]
      # @param options [Hash]
      # @return [Array<String>, Nil] tuple of before and after text or nil if nothing to do
      def self.convert_el(el, options)
        case el.type
        when :a
          # nothing to do
        when :blank
          # nothing to do
        when :em
          if el.has_class?('line_break')
            # line_break, always ignore children
            el.children = []
            if handle_line_break_class?(options)
              # Insert newline
              return ["\n", nil]
            end
          end
          if !include_paragraph_numbers?(options) && el.has_class?('pn')
            # Don't render paragraph number
            el.children = []
          end
          # nothing to do
        when :entity
          # Decode whitelisted entities
          return [Repositext::Utils::EntityEncoder.decode(el.options[:original]), nil]
        when :gap_mark
          # nothing to do
        when :header
          if prefix_header_lines?(options)
            # Prepend line with hash mark, append newline
            return ['# ', "\n"]
          else
            # add a new line for each header
            return [nil, "\n"]
          end
        when :hr
          # put 7 asterisks on new line.
          ["* * * * * * *\n", nil]
        when :p
          if !include_id_elements?(options) && el.is_id?
            # Don't export id elements
            el.children = []
            return nil # Don't render a line break.
          end

          # add a new line for each paragraph
          return [nil, "\n"]
        when :record_mark
          # nothing to do
        when :root
          # nothing to do
        when :strong
          # nothing to do
        when :subtitle_mark
          # Delegate to method for overridability
          return subtitle_mark_output(options)
        when :text
          # capture value of all :text elements
          if options[:convert_to_upper_case]
            return [el.value.unicode_upcase, nil]
          else
            return [el.value, nil]
          end
        else
          raise "Handle this element: #{ el.inspect }"
        end
      end

      # Return true to include line breaks for `.line_break` IAL classes.
      # @param options [Hash]
      def self.handle_line_break_class?(options)
        true
      end

      # Return true to include id
      # @param options [Hash]
      def self.include_id_elements?(options)
        true
      end

      # Return true to include paragraph numbers
      # @param options [Hash]
      def self.include_paragraph_numbers?(options)
        true
      end

      # Return true to prefix header lines with hash marks
      # @param options [Hash]
      def self.prefix_header_lines?(options)
        false
      end

      # Return nil to ignore subtitle_marks.
      # @param options [Hash]
      def self.subtitle_mark_output(options)
        nil
      end

      # Extracts plain text from tree
      # @param [Kramdown::Element] el
      # @param options [Hash{Symbol => Object}] these options will be merged
      #   into @options.
      # @return [String] the plain text
      def convert(el, options = {})
        # Starting with @options, merge in :convert_to_uppercase, then merge
        # in options.
        options = @options.merge(
          {
            convert_to_upper_case: false
          }.merge(options)
        )

        # Detect em.smcaps and convert any contained text to upper case
        if options[:convert_smcaps_to_upper_case] && :em == el.type && el.has_class?('smcaps')
          options[:convert_to_upper_case] = true
        end

        # Convert el to plain_text
        before, after = self.class.convert_el(el, options)

        # Record `before` segment
        @plain_text << before  if before

        # walk the tree
        el.children.each { |e| convert(e, options) }

        # Record `after` segment
        @plain_text << after  if after

        # Return @plain_text after finishing :root el
        if :root == el.type
          # return post_processed @plain_text for :root element
          return post_process_export(@plain_text, options)
        end
      end

      # Post processes the exported plain text.
      # @param raw_plain_text [String]
      # @param options [Hash]
      # @return [String]
      def post_process_export(raw_plain_text, options)
        raw_plain_text.strip
      end

    end
  end
end
