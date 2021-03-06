module Kramdown
  module Parser
    # Parses an IDML story to kramdown.
    class IdmlStory < Base

      include ::Kramdown::AdjacentElementMerger
      include ::Kramdown::ImportWhitespaceSanitizer
      include ::Kramdown::RawTextParser

      class InvalidElementException < RuntimeError; end

      # Maps IDML paragraph styles to kramdown elements
      # @return [Hash] hash with paragraph styles as keys and arrays with the
      # following items as values:
      # * element type: a supported Kramdown::Element type
      # * element value: String or nil
      # * element attr: Hash or nil.
      # * element options (can contain a lambda for lazy execution, gets passed the para XML node)
      def self.paragraph_style_mappings
        {
          "Header"                   => [:header, nil, nil                        , lambda { |para| {:level => 1, :raw_text => para.text} }],
          "Normal"                   => [:p     , nil, {'class' => 'normal'}      , nil],
          "NormalTest"               => [:p     , nil, {'class' => 'normal_test'} , nil],
          "Horizontal rule"          => [:hr    , nil, nil                        , nil],
          "$ID/[No paragraph style]" => [:p     , nil, nil                        , nil]
        }
      end

      # @param [String] source the story's XML as string
      # @param [Hash] options
      def initialize(source, options)
        super
        @stack = [] # the parse stack, see #with_stack for details
        @tree = nil # the current kramdown_element
        @story_name = nil # recorded for position information
        # Re-assign @root to instance of ElementRt, not of Element
        @root = ElementRt.new(:root, nil, nil, :encoding => (source.encoding rescue nil), :location => 1)
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
      # @param kd_el [Kramdown::Element] the current Kramdown::Element.
      # @param xml_node [Nokogiri::Xml::Node]  the current XML node.
      # @param block [Block]
      def with_stack(kd_el, xml_node, &block)
        @stack.push([kd_el, xml_node])
        @tree = kd_el
        yield
      ensure
        @stack.pop
        @tree = @stack.last.first rescue nil
      end

      # Parses all stories in @source and returns parse tree.
      # @return [Kramdown::Element] the root element of the parse tree with all children.
      def parse
        xml = Nokogiri::XML(@source) {|cfg| cfg.noblanks }
        xml.xpath('/idPkg:Story/Story').each do |story|
          with_stack(@root, story) { parse_story(story) }
        end
        update_tree
      end

      # @param [Nokogiri::Xml::Node] story the root node of the story xml
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

      # @param [Nokogiri::Xml::Node] para the xml node for the ParagraphStyleRange
      def parse_para(para)
        el = add_element_for_ParagraphStyleRange(para)
        with_stack(el, para) { parse_para_children(para.children) }
        validation_hook_during_parsing(el, para)
      end

      # Adds a new :p element as child to @tree, depending on the style of para.
      # You can override the style mappings via the `paragraph_style_mappings`
      # method.
      # @param [Nokogiri::Xml::Node] para the xml node for the ParagraphStyleRange
      # @return [Kramdown::Element] the new kramdown element
      def add_element_for_ParagraphStyleRange(para)
        l = { :line => para.line, :story => @story_name }
        el = case para['AppliedParagraphStyle']
        when *(paragraph_style_mappings.keys.map { |e| 'ParagraphStyle/' + e })
          # A known paragraph style that we have a mapping for
          type, value, attr, options = paragraph_style_mappings[para['AppliedParagraphStyle'].gsub('ParagraphStyle/', '')]
          ElementRt.new(
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
          # An unknown paragraph style
          ElementRt.new(
           :p,
           nil,
           {'class' => normalize_style_name(para['AppliedParagraphStyle'])},
           :location => l
         )
        else
          # No AppliedParagraphStyle
          ElementRt.new(:p, nil, nil, :location => l)
        end
        @tree.add_child(el)
        el
      end

      # @param [Array<Nokogiri::Xml::Node>] children an array of xml nodes, one for each child
      def parse_para_children(children)
        children.each do |child|
          case child.name
          when 'CharacterStyleRange'
            parse_char(child)
          when 'Properties'
            # ignore
          else
            raise InvalidElementException, "Found unexpected child element '#{ child.name }' of ParagraphStyleRange on line #{ child.line }"
          end
        end
      end

      # @param [Nokogiri::Xml::Node] char the xml node for the CharacterStyleRange
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
      # @param [Nokogiri::Xml::Node] char the xml node for the CharacterStyleRange
      # @return [Kramdown::Element] the new kramdown element
      def add_element_for_CharacterStyleRange(char)
        el = parent_el = nil
        char_style = :regular
        l = { :story => @story_name, :line => char.line }

        # Only proceed if char has at least one non-empty Content node
        char_has_non_whitespace_content = char.children.any? { |child|
          'Content' == child.name && !child.inner_text.strip.empty?
        }
        return el  unless char_has_non_whitespace_content

        if (
          'CharacterStyle/Bold Italic' == char['AppliedCharacterStyle'] ||
          'Bold Italic' == char['FontStyle']
        )
          # Create pair of nested elements to include both bold and italic styles.
          parent_el = ElementRt.new(:strong, nil, nil, :location => l)
          el = ElementRt.new(:em, nil, nil, :location => l)
          parent_el.add_child(el)
          char_style = :bold_italic
        else
          # TODO: assignment of char_style depends on code execution: if both are present, it will always be 'Italic' and never 'Bold'
          #       Is this ok or intended?
          if (
            'CharacterStyle/Bold' == char['AppliedCharacterStyle'] ||
            'Bold' == char['FontStyle']
          )
            el = parent_el = ElementRt.new(:strong, nil, nil, :location => l)
            char_style = :bold
          end

          if (
            'CharacterStyle/Italic' == char['AppliedCharacterStyle'] ||
            'Italic' == char['FontStyle']
          )
            if parent_el
              el = ElementRt.new(:em, nil, nil, :location => l)
              parent_el.add_child(el)
            else
              el = parent_el = ElementRt.new(:em, nil, nil, :location => l)
            end
            char_style = :italic
          end

        end

        if 'CharacterStyle/$ID/[No character style]' == char['AppliedCharacterStyle']
          # Preserve FontStyles
          if 'Italic' == char['FontStyle']
            el = parent_el = ElementRt.new(:em, nil, nil, :location => l)
            char_style = :italic
          elsif 'Bold' == char['FontStyle']
            el = parent_el = ElementRt.new(:strong, nil, nil, :location => l)
            char_style = :bold
          else
            # No FontStyle applied so we don't need to add any parent elements
            # for this CharacterStyleRange
          end
        end

        add_class_to_self_or_parent = lambda do |css_class|
          parent_el = el = ElementRt.new(:em, nil, nil, :location => l) if el.nil?
          parent_el.add_class(css_class)
          parent_el.add_class(
            case char_style
            when :regular then ''
            when :italic then ' italic'
            when :bold then ' bold'
            when :bold_italic then ' bold italic'
            end
          )
        end

        add_class_to_self_or_parent.call('underline') if 'true' == char['Underline']
        add_class_to_self_or_parent.call('smcaps') if 'SmallCaps' == char['Capitalization']

        if "Color/GAP RED" == char['FillColor']
          (el.nil? ? @tree : el).add_child(
            ElementRt.new(:gap_mark, nil, nil, :location => l)
          )
        end

        if "Color/TRANSLATORS OMIT" == char['FillColor']
          containing_para_ke = @stack.last.first
          if (
            containing_para_ke &&
            :p == containing_para_ke.type
          )
            # append omit class
            containing_para_ke.add_class('omit')
          end
        end

        if 'CharacterStyle/Paragraph number' == char['AppliedCharacterStyle']
          if @tree.has_class?('normal')
            @tree.remove_class('normal')
            @tree.add_class('normal_pn')
          end
          add_class_to_self_or_parent.call('pn')
        end

        if !HANDLED_CHARACTER_STYLES.include?(char['AppliedCharacterStyle'])
          add_class_to_self_or_parent.call(normalize_style_name(char['AppliedCharacterStyle']))
        end

        @tree.add_child(parent_el)  if !parent_el.nil?

        el
      end

      # @param [Array<Nokogiri::Xml::Node>] children an array of xml nodes, one for each child
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
            while text_elements.length > 0
              process_and_add_text(text_elements.shift)
              if text_elements.length > 0
                @tree.add_child(
                  ElementRt.new(:br, nil, nil, :location => { :line => child.line, :story => @story_name })
                )
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
          when 'HyperlinkTextDestination',
               'HyperlinkTextSource'
            # pull node, process children
            parse_char_children(child.children)
          when 'Note',
               'Properties'
            # ignore this
          else
            raise(
              InvalidElementException,
              "Found unexpected child element '#{ child.name }' of CharacterStyleRange on line #{ child.line }"
            )
          end
        end
      end

      # @param [String] name the IDML style name
      # @return [String] the normalized style name
      def normalize_style_name(name)
        name.gsub!(/^ParagraphStyle\/|^CharacterStyle\//, '')
        name.gsub!(/[^A-Za-z0-9_-]/, '-')
        name = "c-#{name}" unless name =~ /^[a-zA-Z]/
        name
      end

      def update_tree
        @stack = [@root]

        iterate_over_children = nil

        ### lambda for managing whitespace
        # el - the parent element to add whitespace element to (as child)
        # index - the place where the whitespace text should be inserted
        # append - true if the whitespace should be appended to existing text
        # → return modified index of element
        add_whitespace = lambda do |el, index, text, append|
          l = el.options[:line]
          if index == -1
            el.add_child(
              ElementRt.new(:text, text, nil, :location => { :line => l, :story => @story_name }),
              0
            )
            1
          elsif index == el.children.length
            el.add_child(
              ElementRt.new(:text, text, nil, :location => { :line =>l, :story => @story_name }),
              index
            )
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
            el.add_child(
              ElementRt.new(:text, text, nil, :location => { :line =>l, :story => @story_name }),
              index
            )
            index + (append ? 1 : -1)
          end
        end

        ### postfix iteration
        # - ensures that whitespace from inner elements is pushed outside first
        process_child = lambda do |el, index|
          iterate_over_children.call(el)
          if el.type == :hr
            el.children.clear
          elsif [:em, :strong].include?(el.type) && el.children.empty?
            # span element is empty and can be completely deleted
            @stack.last.children.delete_at(index)
            index -= 1
          elsif [:header, :p].include?(el.type) && el.children.all? { |e| :text == e.type && '' == e.value.to_s.strip }
            # block element is empty or contains whitespace only and can be removed
            @stack.last.children.delete_at(index)
            index -= 1
          elsif (el.type == :em || el.type == :strong)
            # manage whitespace
            # TODO: If we convert this parser from a stack based approach to the
            # DOM traversal one we use in Kramdown::Parser::Folio, then we can
            # use the Kramdown::Mixins::WhitespaceOutPusher module here.
            if el.children.any? && el.children.first.type == :text && el.children.first.value =~ /\A[[:space:]]+/
              # First child is text and has leading whitespace. Move leading
              # whitespace as sibling before el.
              index = add_whitespace.call(@stack.last, index, Regexp.last_match(0), true)
              el.children.first.value.lstrip!
            end
            if el.children.any? && el.children.last.type == :text && el.children.last.value =~ /[[:space:]]+\Z/
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
          elsif :text == el.type && ['', nil].include?(el.value)
            # element is empty and can be completely deleted
            @stack.last.children.delete_at(index)
            index -= 1
          end

          index
        end

        iterate_over_children = lambda do |el|
          merge_adjacent_child_elements!(el)

          @stack.push(el)
          index = 0
          while index < el.children.length
            index = process_child.call(el.children[index], index)
            index += 1
          end
          @stack.pop

          # needs to run after whitespace has been pushed out so that we won't
          # have a leading \t inside an :em that is the first child in a para.
          # After whitespace is pushed out, the \t will be a direct :text child
          # of :p and first char will be easy to detect.
          recursively_sanitize_whitespace_during_import!(el)

          # merge again since we may have new identical siblings after all the
          # other processing.
          merge_adjacent_child_elements!(el)

          validation_hook_during_update_tree(el)
        end

        iterate_over_children.call(@root)
      end

      # A validation hook during parsing. Override this method for your custom
      # validations.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      # @param [Nokogiri::Xml::Node] xml_node the currently parsed idml node
      def validation_hook_during_parsing(kd_el, xml_node)
        # override this method in validating subclass of self
      end

      # A validation hook during update_tree. Override this method for your custom
      # validations.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      def validation_hook_during_update_tree(kd_el)
        # override this method in validating subclass of self
      end

      # Delegate instance method to class method
      def paragraph_style_mappings
        self.class.paragraph_style_mappings
      end

    end

  end
end
