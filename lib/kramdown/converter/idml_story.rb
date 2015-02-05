# -*- coding: utf-8 -*-

require 'kramdown/converter'
require 'builder'

module Kramdown
  module Converter
    class IdmlStory < Base

      class Exception < RuntimeError; end
      class InvalidElementException < Exception; end
      class UnsupportedElementException < Exception; end

      # Instantiate an IDMLStory converter
      # @param[Kramdown::Element] root
      # @param[Hash] options
      def initialize(root, options)
        super
        @xml = '' # string collector for IDML Story XML
        @xml_stack = [] # for XML nodes
        @stack = [] # for Kramdown elements
      end

      # @return[String] the name of the converter method for element_type
      DISPATCHER = Hash.new {
        |h,element_type| h[element_type] = "convert_#{ element_type }"
      }

      # Converts +el+ and adds result to @xml string
      # @param[Kramdown::Element] el
      def convert(el) #:nodoc:
        send(DISPATCHER[el.type], el)
      end

      # Converts +el+'s child elements
      # @param[Kramdown::Element] el
      def inner(el) #:nodoc:
        @stack.push(el)
        el.children.each {|child| convert(child)}
        @stack.pop
      end

    protected

      # ----------------------------
      # :section: Element conversion methods
      #
      # These methods perform the actual conversion of the element tree using the various IDML tag
      # helper methods.
      #
      # ----------------------------

      # @param[Kramdown::Element] root
      def convert_root(root)
        inner(root)
        emit_end_tag while @xml_stack.size > 0
        @xml
      end

      # @param[Kramdown::Element] el
      def convert_header(el)
        paragraph_style_range_tag(el, 'Header')
      end

      # @param[Kramdown::Element] el
      def convert_p(el)
        if el.has_class?('test_class')
          # This is an example for how to handle an element with a specific class.
          # This class is also used for testing.
          paragraph_style_range_tag(el, 'NormalTest')
        else
          paragraph_style_range_tag(el, 'Normal')
        end
      end

      # @param[Kramdown::Element] el
      def convert_hr(el)
        paragraph_style_range_tag(nil, 'Horizontal rule') do
          char_st_rng_tag(nil, 'Regular') do
            content_tag('* * *')
          end
        end
      end

      # @param[Kramdown::Element] el
      def convert_text(el)
        character_style_range_tag_for_el(el)
        # Transform text contents:
        #   * Remove line breaks from text nodes
        t = el.value.gsub(/\n/, ' ')
        content_tag(unescape_brackets(t))
      end

      # @param[Kramdown::Element] el
      def convert_em(el)
        character_style_range_tag_for_el(el)
      end

      def convert_entity(el)
        # Insert entity as decoded character in its own '<content>' tag
        content_tag(Repositext::Utils::EntityEncoder.decode(el.options[:original]))
      end

      # @param[Kramdown::Element] el
      def convert_strong(el)
        character_style_range_tag_for_el(el)
      end

      # We use +U2028 (LINE SEPARATOR) for kramdown :br elements
      # @param[Kramdown::Element] el
      def convert_br(el)
        character_style_range_tag_for_el(el)
        content_tag("\u2028")
      end

      # @param[Kramdown::Element] el
      def convert_xml_comment(el)
        # noop
      end
      alias_method :convert_xml_pi, :convert_xml_comment
      alias_method :convert_comment, :convert_xml_comment
      alias_method :convert_blank, :convert_xml_comment

      # An exception is raised for all elements that cannot be converted by this converter.
      def method_missing(id, *args, &block)
        if id.to_s =~ /^convert_/
          raise(
            UnsupportedElementException,
            "IDML story converter can't output elements of type #{ id }"
          )
        else
          super
        end
      end

      # ----------------------------
      # :section: Helper methods for easier IDML output
      #
      # These helper methods should be used when outputting any IDML tag.
      #
      # ----------------------------


      # Creates a ParagraphStyleRange tag
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are
      # converted if +el+ is not +nil+.
      #
      # @param[Kramdown::Element] el
      # @param[String] style 'ParagraphStyle/' is automatically prepended
      # @param[Hash, optional] attrs
      def paragraph_style_range_tag(el, style, attrs = {})
        # Close any open tags that are not CharacterStyleRange or ParagraphStyleRange
        while(
          @xml_stack.last && \
          !['CharacterStyleRange', 'ParagraphStyleRange'].include?(@xml_stack.last.first)
        ) do
          emit_end_tag
        end

        attrs = attrs.merge("AppliedParagraphStyle" => "ParagraphStyle/#{ style }")

        # Try to find index of preceding ParagraphStyleRange in @xml_stack.
        prev_para_idx = @xml_stack.size - 1
        while prev_para_idx >= 0 && @xml_stack[prev_para_idx].first != 'ParagraphStyleRange' do
          prev_para_idx -= 1
        end

        if prev_para_idx == -1 || @xml_stack[prev_para_idx].last != attrs
          # No preceding ParagraphStyleRange exists, or its attrs are different
          # from current: Start new ParagraphStyleRange.
          if prev_para_idx != -1
            # Preceding ParagraphStyleRange exists, but attrs are different:
            # insert a br tag and close all open tags.
            br_tag
            (@xml_stack.size - prev_para_idx).times { emit_end_tag }
          end
          emit_start_tag('ParagraphStyleRange', attrs)
        else
          # Preceding ParagraphStyleRange exists and has identical attributes:
          # insert br tag so that we can add children to preceding ParagraphStyleRange.
          br_tag
        end

        # yield if block is given, or convert el's children into current ParagraphStyleRange
        block_given? ? yield : el && inner(el)
      end

      # Creates a CharacterStyleRange tag using #char_st_rng_tag and automatically chooses
      # the correct style for the given element.
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are
      # converted if +el+ is not +nil+.
      #
      # **Note**: Use this method rather than the #char_st_rng_tag method!
      #
      # @param[Kramdown::Element] el
      # @param[Array, optional] ancestors an array holding the ancestors of +el+.
      # @param[Proc, optional] block
      def character_style_range_tag_for_el(el, ancestors = @stack, &block)
        orig_el = el
        if ![:em, :strong].include?(el.type)
          # This is most likely a :text element: Use parent element for further processing.
          # Parent could be e.g., :p, :em, :strong
          el, ancestors = ancestors[-1], ancestors[0..-2]
        end
        if (el.type == :em && ancestors.last.type == :strong) ||
            (el.type == :strong && ancestors.last.type == :em)
          char_st_rng_tag(orig_el, 'Bold Italic', &block)
        elsif el.type == :strong
          char_st_rng_tag(orig_el, 'Bold', &block)
        elsif el.type == :em
          # We use :em to represent spans. Compute class for span:
          style = if el.has_class?('italic') && el.has_class?('bold')
            'Bold Italic'
          elsif el.has_class?('bold')
            'Bold'
          elsif el.has_class?('italic') || '' == el.attr['class'].to_s
            'Italic'
          else
            'Regular'
          end
          attr = {}
          attr['Capitalization'] = 'SmallCaps'  if el.has_class?('smcaps')
          attr['Position'] = 'Subscript'  if el.has_class?('subscript')
          attr['Position'] = 'Superscript'  if el.has_class?('superscript')
          attr['Underline'] = 'true'  if el.has_class?('underline')
          char_st_rng_tag(orig_el, style, attr, &block)
        else
          char_st_rng_tag(orig_el, 'Regular', &block)
        end
      end

      # Creates a CharacterStyleRange tag
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are
      # converted if +el+ is not +nil+.
      #
      # **Note**: You should not call this method directly, but rather #character_style_range_tag_for_el instead!
      #
      # @param[Kramdown::Element] el
      # @param[String] style 'CharacterStyle/' is automatically prepended
      # @param[Hash, optional] attrs
      def char_st_rng_tag(el, style, attrs = {})
        attrs = attrs.merge("AppliedCharacterStyle" => "CharacterStyle/#{ style }")

        if @xml_stack.last.first != 'CharacterStyleRange' || @xml_stack.last.last != attrs
          # There is no preceding CharacterStyleRange, or it has different attrs.
          if @xml_stack.last.first == 'CharacterStyleRange'
            # Preceding CharacterStyleRange has different attrs: close it.
            emit_end_tag
          end
          emit_start_tag('CharacterStyleRange', attrs)
        end

        # yield if block is given, or convert el's children into current CharacterStyleRange
        block_given? ? yield : el && inner(el)
      end

      # @param[String] text
      def content_tag(text)
        emit_start_tag('Content', {}, false, true, false)
        emit_text(text)
        emit_end_tag(false)
      end

      def br_tag
        emit_start_tag('Br', {}, true)
      end


      # ----------------------------
      # :section: Low level XML output methods
      #
      # These helper methods are used for the actual XML output. The library builder is used for its
      # XML escaping functionality.
      #
      # A node based approach instead of direct text output like with nokogiri could have been used,
      # too.
      #
      # ----------------------------


      # Escapes the string so that it works for XML text.
      # @param[String] data
      # @return[String]
      def escape_xml(data)
        Builder::XChar.encode(data)
      end

      # Characters that need to be escaped additionally in attributes
      XML_ATTR_ESCAPES = { "\n" => "&#10;", "\r" => "&#13;", '"' => '&quot;' }
      # The regexp for the characters that need to be escaped
      XML_ATTR_ESCAPES_RE = /[\n\r"]/

      # Escapes the given XML attribute value.
      # @param[String] value
      # @return[String]
      def escape_xml_attr(value)
        escape_xml(value).gsub(XML_ATTR_ESCAPES_RE) { |c| XML_ATTR_ESCAPES[c] }
      end

      # Returns a correctly formatted string for the given attribute key-value pairs.
      # @param[Hash] attrs
      # @return[String]
      def format_attrs(attrs)
        " " << attrs.map { |k,v| "#{ k }=\"#{ escape_xml_attr(v) }\""}.join(' ')
      end

      # Emits the start tag +name+ to @xml.
      # @param[String] name the tag name
      # @param[Hash, optional] attrs the tag's attributes
      # @param[Boolean, optional] is_closed true for self closing tags
      # @param[Boolean, optional] indent true if tag should be indented
      # @param[Boolean, optional] line_break true if \n is to be inserted after
      def emit_start_tag(name, attrs = {}, is_closed = false, indent = true, line_break = true)
        @xml << [
          indent ? '  ' * @xml_stack.size : '',
          "<#{ name }",
          (format_attrs(attrs)  if attrs.any?),
          is_closed ? ' />' : '>',
          ("\n"  if line_break)
        ].compact.join
        @xml_stack.push([name, attrs])  if !is_closed
      end

      # Emits the end tag for the last emitted start tag to @xml.
      # @param[Boolean, optional] indent true if tag should be indented
      # @param[Boolean, optional] line_break true if \n is to be inserted after
      def emit_end_tag(indent = true, line_break = true)
        name, _ = @xml_stack.pop
        @xml << [
          indent ? '  ' * @xml_stack.size : '',
          "</#{ name }>",
          ("\n"  if line_break)
        ].compact.join
      end

      # Emits text to @xml.
      # @param[String] text
      def emit_text(text)
        @xml << escape_xml(text)
      end

    end

  end
end
