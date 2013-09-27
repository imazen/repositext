# -*- coding: utf-8 -*-

require 'kramdown/converter'
require 'builder'

module Kramdown
  module Converter

    class IDMLStory < Base

      class Exception < RuntimeError; end
      class InvalidElementException < Exception; end
      class UnsupportedElementException < Exception; end

      # Create an IDML converter with the given +options+.
      def initialize(root, options)
        super
        @xml = ''
        @xml_stack = []
        @stack = []
      end

      DISPATCHER = Hash.new {|h,k| h[k] = "convert_#{k}"} #:nodoc:

      def convert(el) #:nodoc:
        send(DISPATCHER[el.type], el)
      end

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


      def convert_root(root)
        inner(root)
        emit_end_tag while @xml_stack.size > 0
        @xml
      end

      def convert_header(el)
        case el.options[:level]
        when 1
          para(el, 'Title of Sermon')
        when 3
          para(el, 'Sub-title')
        else
          raise InvalidElementException, "IDML story converter can't output header with levels != 1 | 3"
        end
      end

      def convert_p(el)
        style = case el.attr['class']
                when /\bnormal\b/ then 'Normal'
                when /\bnormal_pn\b/ then 'Normal'
                when /\bscr\b/ then 'Scripture'
                when /\bstanza\b/ then 'Song stanza'
                when /\bsong\b/ then 'Song'
                when /\bid_title1\b/ then 'IDTitle1'
                when /\bid_title2\b/ then 'IDTitle2'
                when /\bid_paragraph\b/ then 'IDParagraph'
                when /\breading\b/ then 'Reading'
                when /\bq\b/
                  text_el = el.children.first
                  text_el = text_el.children.first while text_el && text_el.type != :text

                  raise InvalidElementException, "Paragraph with q class and no number at start of text" unless text_el

                  number = text_el.value.to_s.scan(/\A\d+/).first || ''
                  case number.length
                  when 0 then @para_last_style && @para_last_style =~ /\AQuestion/ ? @para_last_style : 'Question1'
                  when 1 then 'Question1'
                  when 2 then 'Question2'
                  when 3 then 'Question3'
                  end
                end
        para(el, style)
      end

      def convert_hr(el)
        para(nil, 'Horizontal rule') do
          char(nil, 'Regular') do
            content('* * *')
            line_break
          end
        end
      end

      def convert_text(el)
        char_for_el(el) { }
        content(el.value)
      end

      def convert_em(el)
        char_for_el(el)
      end

      def convert_strong(el)
        char_for_el(el)
      end

      def convert_br(el)
        char_for_el(el) { }
        content("\u2028", el)
      end

      def convert_xml_comment(el) #:nodoc:
        # noop
      end
      alias_method :convert_xml_pi, :convert_xml_comment
      alias_method :convert_comment, :convert_xml_comment
      alias_method :convert_blank, :convert_xml_comment

      # An exception is raised for all elements that cannot be converted by this converter.
      def method_missing(id, *args, &block)
        raise UnsupportedElementException, "IDML story converter can't output elements of type #{id}"
      end


      # ----------------------------
      # :section: Helper methods for easier IDML output
      #
      # These helper methods should be used when outputting any IDML tag.
      #
      # ----------------------------


      # Create a ParagraphStyleRange tag with the given style ('ParagraphStyle/' is automatically
      # prepended) and the optional attributes.
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are converted it if is
      # not +nil+.
      def para(el, style, attrs = {})
        emit_end_tag while @xml_stack.last && !['CharacterStyleRange', 'ParagraphStyleRange'].include?(@xml_stack.last.first)

        attrs = attrs.merge("AppliedParagraphStyle" => "ParagraphStyle/#{style}")

        para_index = @xml_stack.size - 1
        para_index -= 1 while para_index >= 0 && @xml_stack[para_index].first != 'ParagraphStyleRange'

        if para_index == -1 || @xml_stack[para_index].last != attrs
          if para_index != -1
            line_break
            (@xml_stack.size - para_index).times { emit_end_tag }
          end
          emit_start_tag('ParagraphStyleRange', attrs)
        else
          line_break
        end

        block_given? ? yield : el && inner(el)
      end

      # Create a CharacterStyleRange tag using #char but automatically choose the correct style for
      # the given element.
      #
      # The +ancestors+ parameter needs to be an array holding the ancestors of the given element.
      #
      # **Note**: This method should normally be used instead of the #char method!
      def char_for_el(el, ancestors = @stack, &block)
        orig_el = el
        orig_el, el, ancestors = el, ancestors[-1], ancestors[0..-2] if el.type != :em && el.type != :strong
        if (el.type == :em && ancestors.last.type == :strong) ||
            (el.type == :strong && ancestors.last.type == :em)
          char(orig_el, 'Bold Italic', &block)
        elsif el.type == :strong
          char(orig_el, 'Bold', &block)
        elsif el.type == :em
          style = if el.attr['class'] =~ /\bpn\b/
                    'Paragraph number'
                  elsif el.attr['class'] =~ /\bitalic\b/ && el.attr['class'] =~ /\bbold\b/
                    'Bold Italic'
                  elsif el.attr['class'] =~ /\bbold\b/
                    'Bold'
                  elsif el.attr['class'] =~ /\bitalic\b/ || el.attr['class'].to_s.empty?
                    'Italic'
                  else
                    'Regular'
                  end
          attr = {}
          attr['Underline'] = 'true' if el.attr['class'] =~ /\bunderline\b/
          attr['Capitalization'] = 'SmallCaps' if el.attr['class'] =~ /\bsmcaps\b/
          char(orig_el, style, attr, &block)
        else
          char(orig_el, 'Regular', &block)
        end
      end

      # Create a CharacterStyleRange tag with the given style ('CharacterStyle/' is automatically
      # prepended) and the optional attributes.
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are converted it if is
      # not +nil+.
      def char(el, style, attrs = {})
        attrs = attrs.merge("AppliedCharacterStyle" => "CharacterStyle/#{style}")

        if @xml_stack.last.first != 'CharacterStyleRange' || @xml_stack.last.last != attrs
          emit_end_tag if @xml_stack.last.first == 'CharacterStyleRange'
          emit_start_tag('CharacterStyleRange', attrs)
        end

        block_given? ? yield : el && inner(el)
      end

      # Create a Content tag with the given text.
      def content(text)
        emit_start_tag('Content', {}, false, true, false)
        emit_text(text)
        emit_end_tag(false)
      end

      # Create a Br tag.
      def line_break
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


      # Escape the string so that it works for XML text.
      def escape_xml(data)
        Builder::XChar.encode(data)
      end

      # Characters that need to be escaped additionally in attributes
      XML_ATTR_ESCAPES = {"\n" => "&#10;", "\r" => "&#13;", '"' => '&quot;'}
      # The regexp for the characters that need to be escaped
      XML_ATTR_ESCAPES_RE = /[\n\r"]/

      # Escape the given XML attribute value.
      def escape_xml_attr(value)
        escape_xml(value).gsub(XML_ATTR_ESCAPES_RE) {|c| XML_ATTR_ESCAPES[c]}
      end

      # Return a correctly formatted string for the given attribute key-value pairs.
      def format_attrs(attrs)
        " " << attrs.map {|k,v| "#{k}=\"#{escape_xml_attr(v)}\""}.join(' ')
      end

      # Emit the start tag +name+, with the given attributes.
      def emit_start_tag(name, attrs = {}, is_closed = false, indent = true, line_break = true)
        @xml << "#{indent ? '  '*@xml_stack.size : ''}<#{name}#{attrs.empty? ? '' : format_attrs(attrs)}#{is_closed ? ' />' : '>'}#{line_break ? "\n" : ''}"
        @xml_stack.push([name, attrs]) if !is_closed
      end

      # Emit the end tag for the last emitted start tag.
      def emit_end_tag(indent = true, line_break = true)
        name, _ = @xml_stack.pop
        @xml << "#{indent ? '  '*@xml_stack.size : ''}</#{name}>#{line_break ? "\n" : ''}"
      end

      # Emit some text.
      def emit_text(text)
        @xml << escape_xml(text)
      end

    end

  end
end
