# -*- coding: utf-8 -*-

require 'kramdown/parser'
require 'nokogiri'

module Kramdown
  module Parser

    class IDMLStory < Base

      class InvalidElementException < RuntimeError; end

      # Create an IDML parser with the given +options+.
      def initialize(source, options)
        super
        @stack = []
        @tree = nil
      end

      def with_stack(kd_el, xml_el)
        @stack.push([kd_el, xml_el])
        @tree = kd_el
        yield
      ensure
        @stack.pop
        @tree = @stack.last.first rescue nil
      end

      def parse #:nodoc:
        xml = Nokogiri::XML(@source) {|cfg| cfg.noblanks }
        xml.xpath('/idPkg:Story/Story').each do |story|
          with_stack(@root, story) { parse_story(story) }
        end
        update_tree
      end

      def parse_story(story)
        story.xpath('ParagraphStyleRange').each do |para|
          parse_para(para)
          # check for last element of CharacterStyleRange equal to <Br /> and therefore for an
          # invalid empty inserted element
          if @tree.children.last.children.length == 0 ||
              (@tree.children.last.children.length == 1 &&
               @tree.children.last.children.first.children.length == 0 &&
               @tree.children.last.children.first.type != :text)
            @tree.children.pop
          end
        end
      end

      def parse_para(para)
        el = add_element_for_ParagraphStyleRange(para)
        with_stack(el, para) { parse_para_children(para.children) }
      end

      def add_element_for_ParagraphStyleRange(para)
        el = case para['AppliedParagraphStyle']
             when "ParagraphStyle/Title of Sermon"
               Element.new(:header, nil, nil, :level => 1, :raw_text => para.text)
             when "ParagraphStyle/Sub-title"
               Element.new(:header, nil, nil, :level => 3, :raw_text => para.text)
             when "ParagraphStyle/Scripture"
               Element.new(:p, nil, {'class' => 'scr'})
             when "ParagraphStyle/Question 1#", "ParagraphStyle/Question 2#", "ParagraphStyle/Question 3#"
               Element.new(:p, nil, {'class' => 'q'})
             when "ParagraphStyle/Song stanza"
               Element.new(:p, nil, {'class' => 'stanza'})
             when "ParagraphStyle/Song"
               Element.new(:p, nil, {'class' => 'song'})
             when "ParagraphStyle/IDTitle1"
               Element.new(:p, nil, {'class' => 'id_title1'})
             when "ParagraphStyle/IDTitle2"
               Element.new(:p, nil, {'class' => 'id_title2'})
             when "ParagraphStyle/IDParagraph"
               Element.new(:p, nil, {'class' => 'id_paragraph'})
             when "ParagraphStyle/Reading"
               Element.new(:p, nil, {'class' => 'reading'})
             when "ParagraphStyle/Normal"
               Element.new(:p, nil, {'class' => 'normal'})
             when "ParagraphStyle/Horizontal rule"
               Element.new(:hr)
             else
               Element.new(:p)
             end
        @tree.children << el
        el
      end


      def parse_para_children(children)
        children.each do |child|
          case child.name
          when 'CharacterStyleRange'
            parse_char(child)
          when 'Properties'
            # ignore
          else
            raise InvalidElementException, "Found unexpected child element #{child.name} of ParagraphStyleRange"
          end
        end
      end

      def parse_char(char)
        el = add_element_for_CharacterStyleRange(char)
        with_stack(el || @tree, char) { parse_char_children(char.children) }
      end

      def add_element_for_CharacterStyleRange(char)
        el = parent_el = nil

        if char['AppliedCharacterStyle'] == 'CharacterStyle/Bold' || char['FontStyle'] == 'Bold'
          el = parent_el = Element.new(:strong)
        end

        if char['AppliedCharacterStyle'] == 'CharacterStyle/Italic' || char['FontStyle'] == 'Italic'
          if parent_el
            el = Element.new(:em)
            parent_el.children << el
          else
            el = parent_el = Element.new(:em)
          end
        end

        add_class = lambda do |css_class|
          parent_el = el = Element.new(:em) if el.nil?
          parent_el.attr['class'] = ((parent_el.attr['class'] || '') << " #{css_class}").lstrip
        end

        add_class.call('underline') if char['Underline'] == 'true'
        add_class.call('smcaps') if char['Capitalization'] == 'SmallCaps'

        if char['FillColor'] == "Color/GAP RED"
          (el.nil? ? @tree : el).children << Element.new(:line_synchro_marker)
        end

        if char['AppliedCharacterStyle'] == 'CharacterStyle/Paragraph number' && @tree.attr['class'] =~ /\bnormal\b/
          @tree.attr['class'].sub!(/\bnormal\b/, 'normal-pn')
        end

        @tree.children << parent_el if !parent_el.nil?

        el
      end

      def parse_char_children(children)
        children.each do |child|
          case child.name
          when 'Content'
            text_elements = child.content.split("\u2028")
            while text_elements.length > 0
              add_text(text_elements.shift)
              @tree.children << Element.new(:br) if text_elements.length > 0
            end
          when 'Br'
            char_level = @stack.pop
            para_level = @stack.pop
            @tree = @stack.last.first

            para_el = add_element_for_ParagraphStyleRange(para_level.last)
            @stack.push([para_el, para_level.last])
            @tree = para_el

            char_el = add_element_for_CharacterStyleRange(char_level.last)
            @stack.push([char_el || @tree, char_level.last])
            @tree = char_el || @tree
          when 'Properties'
            # ignore this
          else
            raise InvalidElementException, "Found unexpected child element #{child.name} of CharacterStyleRange"
          end
        end
      end

      def update_tree
        @stack = [@root]

        iterate_over_children = nil

        ### lambda for managing whitespace
        # index - the place where the whitespace text should be inserted
        # append - true if the whitespace should be appended to existing text
        # → return modified index of element
        add_whitespace = lambda do |el, index, text, append|
          if index == -1
            el.children.insert(0, Element.new(:text, text))
            1
          elsif index == el.children.length
            el.children.insert(index, Element.new(:text, text))
            index - 1
          elsif el.children[index].type == :text
            if append
              el.children[index].value << text
              index + 1
            else
              el.children[index].value.prepend(text)
              index - 1
            end
          else
            el.children.insert(index, Element.new(:text, text))
            index + (append ? 1 : -1)
          end
        end

        ### lambda for joining adjacent :em/:strong elements
        # parent - the parent element
        # index - index of the element that should be joined
        # → return modified index of last processed element
        try_join_elements = lambda do |parent, index|
          el = parent.children[index]
          prev = parent.children[index-1]
          prev2 = parent.children[index-2]
          if index == 0
            # nothing to do here
            index
          elsif prev.type == el.type && prev.attr == el.attr && prev.options == el.options
            # preceeding element has same data
            prev.children.concat(el.children)
            parent.children.delete_at(index)
            index - 1
          elsif index >= 2 && prev.type == :text && prev.value.strip.empty? &&
              prev2.type == el.type && prev2.attr == el.attr && prev2.options == el.options
            # preceeding element is :text with just whitespace, element before that has same data
            prev2.children.push(prev)
            prev2.children.concat(el.children)
            parent.children.delete_at(index)
            parent.children.delete_at(index-1)
            index - 2
          else
            index
          end
        end

        ### postfix iteration
        # - ensures that whitespace from inner elements is pushed outside first
        process_child = lambda do |el, index|
          iterate_over_children.call(el)

          if el.type == :hr
            el.children.clear
          elsif el.type == :p && el.attr['class'] =~ /\bnormal\b/ &&
              el.children.first.type == :text
            el.children.first.value.sub!(/\A\t/, '')
          elsif el.type == :text && index != 0 && @stack.last.children[index-1].type == :text
            @stack.last.children[index-1].value += el.value
            @stack.last.children.delete_at(index)
            index -= 1
          elsif (el.type == :em || el.type == :strong) && el.children.length == 0
            # check if element is empty and can be completely deleted
            @stack.last.children.delete_at(index)
            index -= 1
          elsif (el.type == :em || el.type == :strong)
            # manage whitespace
            if el.children.first.type == :text && el.children.first.value =~ /\A[[:space:]]+/
              index = add_whitespace.call(@stack.last, index - 1, Regexp.last_match(0), true)
              el.children.first.value.lstrip!
            end
            if el.children.last.type == :text && el.children.last.value =~ /[[:space:]]+\Z/
              index = add_whitespace.call(@stack.last, index + 1, Regexp.last_match(0), false)
              el.children.last.value.rstrip!
            end

            # join neighbour elements and then, possibly, text elements
            index = try_join_elements.call(@stack.last, index)
            iterate_over_children.call(@stack.last.children[index])
          end
          index
        end

        iterate_over_children = lambda do |el|
          @stack.push(el)
          index = 0
          while index < el.children.length
            index = process_child.call(el.children[index], index)
            index += 1
          end
          @stack.pop
        end

        iterate_over_children.call(@root)
      end

    end

  end
end
