# -*- coding: utf-8 -*-

# Added validation hooks
# Added position information to each Element's options [:line, :story]

require 'kramdown/parser'
require 'nokogiri'

module Kramdown
  module Parser

    class IdmlStory < Base

      class InvalidElementException < RuntimeError; end

      # @param[String] source the story's XML as string
      # @param[Hash] options
      def initialize(source, options)
        super
        @stack = [] # the parse stack, see #with_stack for details
        @tree = nil # the current kramdown_element
        @story_name = nil # recorded for position information
      end

      # Called from parse_para and parse_char to manage the stack. Puts the
      # current kramdown_element (kd_el) and the currently parsed XML node (xml_node)
      # onto the stack as last item before processing the children of the current
      # element/node. Removes the current element/node from the stack when done.
      #
      # This is what the stack looks like when parsing an em inside a character
      # style range:
      # [
      #   [<:root element>, <Story xml>],
      #   [<:p element>, <ParagraphStyleRange xml>],
      #   [<:em element>, <CharacterStyleRange xml>]
      # ]
      #
      # @param[Kramdown::Element] kd_el the current Kramdown::Element.
      # @param[Nokogiri::Xml::Node] xml_node the current XML node.
      def with_stack(kd_el, xml_node)
        @stack.push([kd_el, xml_node])
        @tree = kd_el
        yield
      ensure
        @stack.pop
        @tree = @stack.last.first rescue nil
      end

      # Parses all stories in @source and returns parse tree.
      # @return[Kramdown::Element] the root element of the parse tree with all children.
      def parse
        xml = Nokogiri::XML(@source) {|cfg| cfg.noblanks }
        xml.xpath('/idPkg:Story/Story').each do |story|
          with_stack(@root, story) { parse_story(story) }
        end
        update_tree
      end

      # Overrides method from Kramdown::Parser::Base to add location information
      def add_text(text, tree = @tree, type = @text_type)
        if tree.children.last && tree.children.last.type == type
          tree.children.last.value << text
        elsif !text.empty?
          tree.children << Element.new(type, text, nil, :location => tree.options[:location])
        end
      end

      # @param[Nokogiri::Xml::Node] story the root node of the story xml
      def parse_story(story)
        @story_name = story['Self']
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

      # @param[Nokogiri::Xml::Node] para the xml node for the ParagraphStyleRange
      def parse_para(para)
        el = add_element_for_ParagraphStyleRange(para)
        with_stack(el, para) { parse_para_children(para.children) }
        validation_hook_during_parsing(el, para)
      end

      # Maps IDML paragraph styles to kramdown elements
      # @return[Hash] hash with paragraph styles as keys and arrays with the
      # following items as values:
      # * element type: a supported Kramdown::Element type
      # * element value: String or nil
      # * element attr: Hash or nil.
      # * element options (can contain a lambda for lazy execution, gets passed the para XML node)
      def paragraph_style_mappings
        {
          "Title of Sermon"          => [:header, nil, nil                        , lambda { |para| {:level => 1, :raw_text => para.text} }],
          "Sub-title"                => [:header, nil, nil                        , lambda { |para| {:level => 3, :raw_text => para.text} }],
          "Scripture"                => [:p     , nil, {'class' => 'scr'}         , nil],
          "Question1"                => [:p     , nil, {'class' => 'q'}           , nil],
          "Question2"                => [:p     , nil, {'class' => 'q'}           , nil],
          "Question3"                => [:p     , nil, {'class' => 'q'}           , nil],
          "Song stanza"              => [:p     , nil, {'class' => 'stanza'}      , nil],
          "Song"                     => [:p     , nil, {'class' => 'song'}        , nil],
          "IDTitle1"                 => [:p     , nil, {'class' => 'id_title1'}   , nil],
          "IDTitle2"                 => [:p     , nil, {'class' => 'id_title2'}   , nil],
          "IDParagraph"              => [:p     , nil, {'class' => 'id_paragraph'}, nil],
          "Reading"                  => [:p     , nil, {'class' => 'reading'}     , nil],
          "Normal"                   => [:p     , nil, {'class' => 'normal'}      , nil],
          "Horizontal rule"          => [:hr    , nil, nil                        , nil],
          "$ID/[No paragraph style]" => [:p     , nil, nil                        , nil]
        }
      end

      # Adds a new :p element as child to @tree, depending on the style of para.
      # You can override the style mappings via the #paragraph_style_mappings
      # method.
      # @param[Nokogiri::Xml::Node] para the xml node for the ParagraphStyleRange
      # @return[Kramdown::Element] the new kramdown element
      def add_element_for_ParagraphStyleRange(para)
        l = { :line => para.line, :story => @story_name }
        el = case para['AppliedParagraphStyle']
        when *(paragraph_style_mappings.keys.map { |e| 'ParagraphStyle/' + e })
          type, value, attr, options = paragraph_style_mappings[para['AppliedParagraphStyle'].gsub('ParagraphStyle/', '')]
          Element.new(
            type,
            value,
            attr,
            if options.respond_to?(:call)
              { :location => l }.merge(options.call(para))
            else
              { :location => l }.merge(options || {})
            end
          )
        when String
          Element.new(
           :p,
           nil,
           {'class' => normalize_style_name(para['AppliedParagraphStyle'])},
           :location => l
         )
        else
          Element.new(:p, nil, nil, :location => l)
        end
        @tree.children << el
        el
      end

      # @param[Array<Nokogiri::Xml::Node>] children an array of xml nodes, one for each child
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

      # @param[Nokogiri::Xml::Node] char the xml node for the CharacterStyleRange
      def parse_char(char)
        el = add_element_for_CharacterStyleRange(char)
        with_stack(el || @tree, char) { parse_char_children(char.children) }
        validation_hook_during_parsing(el, char)
      end

      HANDLED_CHARACTER_STYLES = ['CharacterStyle/$ID/[No character style]',
                                  'CharacterStyle/Bold',
                                  'CharacterStyle/Bold Italic',
                                  'CharacterStyle/Italic',
                                  'CharacterStyle/Paragraph number',
                                  'CharacterStyle/Regular']

      # Creates a Kramdown::Element for the currently parsed CharacterStyleRange
      # and adds the new element to the tree. We do this to preserve any formatting
      # of the CharacterStyleRange node.
      # @param[Nokogiri::Xml::Node] char the xml node for the CharacterStyleRange
      # @return[Kramdown::Element] the new kramdown element
      def add_element_for_CharacterStyleRange(char)
        el = parent_el = nil
        char_style = :regular
        l = { :story => @story_name, :line => char.line }

        # Only proceed if char has at least one non-empty Content node
        char_has_non_whitespace_content = char.children.any? { |child|
          'Content' == child.name && !child.inner_text.strip.empty?
        }
        return el  unless char_has_non_whitespace_content

        if char['AppliedCharacterStyle'] == 'CharacterStyle/Bold Italic'
          # Create pair of nested elements to include both bold and italic styles.
          parent_el = Element.new(:strong, nil, nil, :location => l)
          el = Element.new(:em, nil, nil, :location => l)
          parent_el.children << el
          char_style = :bold_italic
        else
          # TODO: assignment of char_style depends on code execution: if both are present, it will always be 'Italic' and never 'Bold'
          #       Is this ok or intended?
          if char['AppliedCharacterStyle'] == 'CharacterStyle/Bold' || char['FontStyle'] == 'Bold'
            el = parent_el = Element.new(:strong, nil, nil, :location => l)
            char_style = :bold
          end

          if char['AppliedCharacterStyle'] == 'CharacterStyle/Italic' || char['FontStyle'] == 'Italic'
            if parent_el
              el = Element.new(:em, nil, nil, :location => l)
              parent_el.children << el
            else
              el = parent_el = Element.new(:em, nil, nil, :location => l)
            end
            char_style = :italic
          end

        end

        if char['AppliedCharacterStyle'] == 'CharacterStyle/$ID/[No character style]'
          # Preserve FontStyles
          if 'Italic' == char['FontStyle']
            el = parent_el = Element.new(:em, nil, nil, :location => l)
            char_style = :italic
          elsif 'Bold' == char['FontStyle']
            el = parent_el = Element.new(:strong, nil, nil, :location => l)
            char_style = :bold
          else
            # No FontStyle applied so we don't need to add any parent elements
            # for this CharacterStyleRange
          end
        end

        add_class = lambda do |css_class|
          parent_el = el = Element.new(:em, nil, nil, :location => l) if el.nil?
          parent_el.attr['class'] = ((parent_el.attr['class'] || '') << " #{css_class}").lstrip
          parent_el.attr['class'] += case char_style
                                     when :regular then ''
                                     when :italic then ' italic'
                                     when :bold then ' bold'
                                     when :bold_italic then ' bold italic'
                                     end
        end

        add_class.call('underline') if char['Underline'] == 'true'
        add_class.call('smcaps') if char['Capitalization'] == 'SmallCaps'

        if char['FillColor'] == "Color/GAP RED"
          (el.nil? ? @tree : el).children << Element.new(:gap_mark, nil, nil, :location => l)
        end

        if char['AppliedCharacterStyle'] == 'CharacterStyle/Paragraph number'
          # TODO: - matches word boundary, resulting in normal-pn-pn.
          @tree.attr['class'].sub!(/\bnormal\b/, 'normal-pn') if @tree.attr['class'] =~ /\bnormal\b/
          add_class.call('pn')
        end

        if !HANDLED_CHARACTER_STYLES.include?(char['AppliedCharacterStyle'])
          add_class.call(normalize_style_name(char['AppliedCharacterStyle']))
        end

        @tree.children << parent_el if !parent_el.nil?

        el
      end

      # @param[Array<Nokogiri::Xml::Node>] children an array of xml nodes, one for each child
      def parse_char_children(children)
        children.each do |child|
          case child.name
          when 'Content'
            # Split on LINE SEPARATOR unicode char before we entity encode legitimate
            # special chars. This makes it possible to insert &#x2028 in a document
            # without triggering a line break at that position.
            text_elements = child.inner_text.split("\u2028")
            # Entity encode any legitimate special characters. We have to do
            # it after Nokogiri is done parsing since Nokogiri converts all
            # encoded entities to their character representations and thus undoes
            # what we're trying to accomplish here, i.e. it converts &amp; => '&'
            text_elements = text_elements.map { |te|
              te.gsub(/[\u00A0\u2011\u2028\u202F\uFEFF]/) { |match|
                sprintf('&#x%04X;', match.codepoints.first)
              }
            }
            while text_elements.length > 0
              add_text(text_elements.shift)
              if text_elements.length > 0
                @tree.children << Element.new(:br, nil, nil, :location => { :line => child.line, :story => @story_name })
              end
            end
          when 'Br'
            # Convert <Br> node to :p element
            # The new :p element inherits the styles from the parent char and para
            # xml nodes.
            char_level = @stack.pop
            para_level = @stack.pop
            @tree = @stack.last.first

            para_el = add_element_for_ParagraphStyleRange(para_level.last)
            @stack.push([para_el, para_level.last])
            @tree = para_el

            char_el = add_element_for_CharacterStyleRange(char_level.last)
            @stack.push([char_el || @tree, char_level.last])
            @tree = char_el || @tree
          when 'Properties', 'HyperlinkTextDestination'
            # ignore this
          else
            raise InvalidElementException, "Found unexpected child element #{child.name} of CharacterStyleRange"
          end
        end
      end

      # @param[String] name the IDML style name
      # @return[String] the normalized style name
      def normalize_style_name(name)
        name.gsub!(/^ParagraphStyle\/|^CharacterStyle\//, '')
        name.gsub!(/[^A-Za-z0-9_-]/, '-')
        name = "c-#{name}" unless name =~ /^[a-zA-Z]/
        name
      end

      def update_tree
        @stack = [@root]

#Kramdown::Converter::Graphviz.send(:new, @root, { :graphviz_output_file => 'before.png'}).convert(@root)

        iterate_over_children = nil

        ### lambda for managing whitespace
        # el - the parent element to add whitespace element to (as child)
        # index - the place where the whitespace text should be inserted
        # append - true if the whitespace should be appended to existing text
        # → return modified index of element
        add_whitespace = lambda do |el, index, text, append|
          l = el.options[:line]
          if index == -1
            el.children.insert(0, Element.new(:text, text, nil, :location => { :line => l, :story => @story_name }))
            1
          elsif index == el.children.length
            el.children.insert(index, Element.new(:text, text, nil, :location => { :line =>l, :story => @story_name }))
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
            el.children.insert(index, Element.new(:text, text, nil, :location => { :line =>l, :story => @story_name }))
            index + (append ? 1 : -1)
          end
        end

        ### join adjacent :em/:strong elements
        # parent - the parent element
        # index - index of the element that should be joined
        # → return modified index of last processed element
        try_join_elements = lambda do |el|
          index = 0
          while index < el.children.length - 1
            cur_el = el.children[index]
            next_el = el.children[index + 1]
            next_next_el = el.children[index + 2]
            if(
              cur_el.type == next_el.type &&
              cur_el.attr == next_el.attr &&
              cur_el.options.select {|k,v| :location != k } == next_el.options.select {|k,v| :location != k }
            )
              if cur_el.type == :text
                cur_el.value += next_el.value
              else
                cur_el.children.concat(next_el.children)
              end
              el.children.delete_at(index + 1)
            elsif(
              next_next_el && [:em, :strong].include?(next_next_el.type) &&
              next_el.type == :text && next_el.value.strip.empty? &&
              next_next_el.type == cur_el.type && next_next_el.attr == cur_el.attr &&
              cur_el.options.select {|k,v| :location != k } == next_el.options.select {|k,v| :location != k }
            )
              cur_el.children.push(next_el)
              cur_el.children.concat(next_next_el.children)
              # Important: delete_at index+2 first, so that the other element is still
              # at index+1. If we delete index+1 first, then the other element
              # we want to delete is not at index+2 any more, but has moved up to index+1
              el.children.delete_at(index + 2)
              el.children.delete_at(index + 1)
            else
              index += 1
            end
          end
        end

        ### postfix iteration
        # - ensures that whitespace from inner elements is pushed outside first
        process_child = lambda do |el, index|
          iterate_over_children.call(el)
          if el.type == :hr
            el.children.clear
          elsif el.type == :p && (el.attr['class'] =~ /\bnormal\b/ || el.attr['class'] =~ /\bq\b/) &&
              el.children.first.type == :text
            # remove leading tab from 'normal' and 'q' paragraphs
            el.children.first.value.sub!(/\A\t/, '')
          elsif (el.type == :em || el.type == :strong) && el.children.length == 0
            # element is empty and can be completely deleted
            @stack.last.children.delete_at(index)
            index -= 1
          elsif (el.type == :em || el.type == :strong)
            # manage whitespace
            if el.children.first.type == :text && el.children.first.value =~ /\A[[:space:]]+/
              # First child is text and has leading whitespace. Move leading
              # whitespace as sibling before el.
              index = add_whitespace.call(@stack.last, index, Regexp.last_match(0), true)
              el.children.first.value.lstrip!
            end
            if el.children.last.type == :text && el.children.last.value =~ /[[:space:]]+\Z/
              # Last child is text and has trailing whitespace. Move trailing
              # whitespace to parent of el.
              index = add_whitespace.call(@stack.last, index + 1, Regexp.last_match(0), false)
              el.children.last.value.rstrip!
            end
            if el.children.all? { |c| :text == c.type && '' == c.value }
              # Delete el if removal of whitespace leaves el with all empty text childlren
              @stack.last.children.delete(el)
              index -= 1
            end
          end

#Kramdown::Converter::Graphviz.send(:new, @root, { :graphviz_output_file => 'after.png'}).convert(@root)

          index
        end

        iterate_over_children = lambda do |el|
          try_join_elements.call(el) if el.children.first && ::Kramdown::Element.category(el.children.first) == :span

          @stack.push(el)
          index = 0
          while index < el.children.length
            index = process_child.call(el.children[index], index)
            index += 1
          end
          @stack.pop

          validation_hook_during_update_tree(el)
        end

        iterate_over_children.call(@root)
      end

      # A validation hook during parsing. Override this method for your custom
      # validations.
      # @param[Kramdown::Element] kd_el the kramdown element for xml_node
      # @param[Nokogiri::Xml::Node] xml_node the currently parsed idml node
      def validation_hook_during_parsing(kd_el, xml_node)
        # override this method in validating subclass of self
      end

      # A validation hook during update_tree. Override this method for your custom
      # validations.
      # @param[Kramdown::Element] kd_el the kramdown element for xml_node
      def validation_hook_during_update_tree(kd_el)
        # override this method in validating subclass of self
      end

    end

  end
end
