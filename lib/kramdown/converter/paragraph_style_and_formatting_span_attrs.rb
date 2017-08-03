module Kramdown
  module Converter

    # Converts kramdown tree to a nested datastructure that describes each
    # paragraph's style and its contained formatting spans.
    # Returns an Array of hashes, one for each block level element (except record_marks):
    # [
    #   {
    #     type: :p,
    #     paragraph_styles: ["normal", "first_par"],
    #     formatting_spans: [:italic, :smcaps],
    #     line_number: 3,
    #     plain_text_contents: "first forty characters of paragraph"
    #   },
    #   ...
    # ]
    class ParagraphStyleAndFormattingSpanAttrs < KramdownRepositext

      # Instantiate a converter
      # @param [Kramdown::Element] root
      # @param [Hash{Symbol => Object}] options
      def initialize(root, options)
        super
        @block_elements = [] # collector for block level objects
        @current_block = nil
      end

      # Override any element specific convert methods that require overrides:

      def convert_em(el, opts)
        el_classes = el.get_classes
        formatting_attrs = []
        if el_classes.empty?
          formatting_attrs = [:italic]
        else
          el_classes.each { |el_class|
            case el_class
            when 'bold'
              formatting_attrs << :bold
            when 'italic'
              formatting_attrs << :italic
            when 'line_break'
              # ignore
            when 'pn'
              # ignore
            when 'smcaps'
              formatting_attrs << :smcaps
            when 'subscript'
              formatting_attrs << :subscript
            when 'superscript'
              formatting_attrs << :superscript
            when 'underline'
              formatting_attrs << :underline
            else
              raise "Handle this: #{ el.element_summary }"
            end
          }
        end
        @current_block[:formatting_spans] |= formatting_attrs
        inner(el, opts)
        ''
      end

      def convert_header(el, opts)
        start_new_block_element(
          type: :header,
          plain_text_contents: el.to_plain_text,
          line_number: el.options[:location]
        )
        inner(el, opts)
        ''
      end

      def convert_hr(el, opts)
        start_new_block_element(type: :hr)
        inner(el, opts)
        ''
      end

      def convert_p(el, opts)
        start_new_block_element(
          type: :p,
          paragraph_styles: el.get_classes,
          plain_text_contents: el.to_plain_text.strip.truncate(40),
          line_number: el.options[:location]
        )
        inner(el, opts)
        @current_block[:formatting_spans].sort!
        ''
      end

      def convert_record_mark(el, opts)
        # Pull record marks
        inner(el, opts)
        ''
      end

      def convert_root(el, opts)
        inner(el, opts) # convert child elements
        return @block_elements
      end

      def convert_strong(el, opts)
        @current_block[:formatting_spans] |= [:bold]
        if el.get_classes.any?
          # We assume that strongs don't have classes.
          raise "Handle this: #{ el.element_summary }"
        end
        inner(el, opts)
        ''
      end

      # Wrapper method to start a new block level element.
      def start_new_block_element(attrs)
        @current_block = {
          formatting_spans: [],
          paragraph_styles: [],
          plain_text_contents: '',
        }.merge(attrs)
        @block_elements << @current_block
      end

    end
  end
end
