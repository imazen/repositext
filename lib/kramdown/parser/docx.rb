# TODO: Add .first_par class to first paragraph
require 'kramdown/document'

module Kramdown
  module Parser

    # Parses DOCX XML string to kramdown AT
    #
    # Naming conventions
    #
    # * node: refers to a Nokogiri::XML::Node (XML space)
    # * element: refers to a Kramdown::Element (kramdown space). Note that we actually
    #   use a sub-class named Kramdown::ElementRt
    # * ke: l_var that refers to a kramdown element
    # * xn: l_var that refers to an XML node
   class Docx

      include Kramdown::AdjacentElementMerger
      include Kramdown::ImportWhitespaceSanitizer
      include Kramdown::NestedEmsProcessor
      include Kramdown::TreeCleaner
      include Kramdown::WhitespaceOutPusher

      # Custom error
      class InvalidElementException < RuntimeError; end

      # Represents a TextRunFormat's attributes.
      # @attr_reader bold [Boolean]
      # @attr_reader italic [Boolean]
      # @attr_reader smcaps [Boolean]
      # @attr_reader subscript [Boolean]
      # @attr_reader superscript [Boolean]
      # @attr_reader underline [Boolean]
      class TextRunFormatAttrs

        SUPPORTED_TEXT_RUN_FORMAT_ATTRS = %i[
          bold
          italic
          smcaps
          subscript
          superscript
          underline
        ].sort

        attr_reader *SUPPORTED_TEXT_RUN_FORMAT_ATTRS

        # @param text_run [Nokogiri::XML::Node] the text_run's XML node
        def initialize(text_run)
          tr_style = text_run.at_xpath('./w:rPr')
          if tr_style
            # NOTE: w:b, w:i, and w:smallCaps are supposed to be a toggle properties
            # (<w:b/>), however in some DOCX documents (ODT -> DOC -> DOCX), they
            # have an unexpected `val` attribute that we need to check
            # (<w:b w:val="false"/>). They could also be set to '0' if saved from MS Word.
            @bold = (xn = tr_style.at_xpath('./w:b')) && !%w[false 0].include?(xn['w:val'])
            @italic = (xn = tr_style.at_xpath('./w:i')) && !%w[false 0].include?(xn['w:val'])
            @smcaps = (xn = tr_style.at_xpath('./w:smallCaps')) && !%w[false 0].include?(xn['w:val'])
            @subscript = tr_style.at_xpath("./w:vertAlign[@w:val='subscript']")
            @superscript = tr_style.at_xpath("./w:vertAlign[@w:val='superscript']")
            @underline = (xn = tr_style.at_xpath('./w:u')) && 'none' != xn['w:val'] # val 'none' turns off underline
          end
        end

        # Returns an array with symbols of all applied attributes, sorted
        # alphabetically
        def applied_attrs
          @applied_attrs ||= SUPPORTED_TEXT_RUN_FORMAT_ATTRS.find_all { |e|
            self.send(e)
          }
        end

      end

      # The hash with the parsing options.
      attr_reader :options

      # The array with the parser warnings.
      attr_reader :warnings

      # The original source string.
      attr_reader :source

      # The root element of element tree that is created from the source string.
      attr_reader :root

      # Maps DOCX paragraph style ids to kramdown elements
      # @return [Hash] Hash with paragraph style ids as keys and arrays with the
      # following items as values:
      # * element type: a supported Kramdown::Element type
      # * element value: String or nil
      # * element attr: Hash or nil.
      # * element options (can contain a lambda for lazy execution, gets passed the para XML node)
      def self.paragraph_style_mappings
        {
          "header1"        => [:header, nil, { }                      , lambda { |para| {:level => 1, :raw_text => para.text} }],
          "header2"        => [:header, nil, { }                      , lambda { |para| {:level => 2, :raw_text => para.text} }],
          "header3"        => [:header, nil, { }                      , lambda { |para| {:level => 3, :raw_text => para.text} }],
          "normal"         => [:p     , nil, {'class' => 'normal'}    , nil],
          "paraTest"       => [:p     , nil, {'class' => 'para_test'} , nil],
          "horizontalRule" => [:hr    , nil, { }                      , nil],
        }
      end

      # Parse the +source+ string into an element tree, possibly using the parsing +options+, and
      # return the root element of the element tree and an array with warning messages.
      # @param source [String] contents of word/document.xml as string
      # @param options [Hash, optional] these will be passed to Kramdown::Parser instance
      def self.parse(source, options = {})
        parser = new(source, options)
        parser.parse
        [parser.root, parser.warnings]
      end

      # @note We change the default kramdown parser behavior where you can't
      # just create a parser instance. This makes it easier to use this parser
      # for validation purpose, and to tie it into our workflows.
      #
      # @param source [String] contents of word/document.xml as string
      # @param options [Hash, optional] these will be passed to Kramdown::Parser
      def initialize(source, options)
        @source = source
        @options = {
          :line_width => 100000, # set to very large value so that each para is on a single line
          :input => 'KramdownRepositext' # that is what we generate as string below
        }.merge(options)
        @root = nil
        @warnings = []
      end

      # Parses @source into a Kramdown tree under @root.
      def parse
        @root = Kramdown::ElementRt.new(
          :root, nil, nil, :encoding => 'UTF-8', :location => { :line => 1 }
        )
        @ke_context = Folio::KeContext.new({ 'root' => @root }, self)
        # Transform the XML tree
        xml_document = Nokogiri::XML(@source) { |config| config.noblanks }
        body_xn = xml_document.at_xpath('//w:document//w:body')
        body_xn.children.each do |child_xn|
          process_xml_node(child_xn)
        end
        post_process_kramdown_tree!(@ke_context.get('root', nil))
      end

      # @param [Nokogiri::XML::Node] xn the XML Node to process
      # @param [String] message
      def add_warning(xn, message)
        if '' != message.to_s
          @warnings << {
            message: message,
            line: xn.line,
            path: xn.name_and_class_path
          }
        end
      end

    private

      # Processes an xml_node
      # @param xn [Nokogiri::XML::Node] the XML Node to process
      def process_xml_node(xn)
        raise(InvalidElementException, "xn cannot be nil")  if xn.nil?
        # TODO: Don't use OpenStruct here for performance reasons.
        @xn_context = OpenStruct.new(
          :match_found => false,
          :process_children => true,
        )
        if xn.duplicate_of?(xn.parent)
          # xn is duplicate of its parent, pull it
          pull_node(xn)
          @xn_context.match_found = true
        else
          method_name = "process_node_#{ xn.name.downcase.gsub('-', '_') }"
          if respond_to?(method_name, true)
            self.send(method_name, xn)
          else
            raise InvalidElementException.new(
              "Unexpected element type #{ xn.name } on line #{ xn.line }. Requires method #{ method_name.inspect }."
            )
          end
        end
        if !@xn_context.match_found
          add_warning(xn, "Unhandled XML node #{ xn.name_and_class }")
        end
        # recurse over child XML Nodes
        if @xn_context.process_children
          xn.children.each { |xnc| process_xml_node(xnc) }
        end
      end

      # Modifies kramdown_tree in place.
      # NOTE: this method has potential for optimization. We blindly run
      # recursively_merge_adjacent_elements in a number of places. This is only
      # necessary if the previous methods actually modified the tree.
      # I'm thinking only if nodes were removed, however that needs to be
      # confirmed.
      # @param kramdown_tree [Kramdown::Element] the root of the tree
      def post_process_kramdown_tree!(kramdown_tree)
        # override this to post process elements in the kramdown tree
        # NOTE: It's important to call the methods below for correct results.
        # You have two options:
        # 1. call super if you override this method
        # 2. copy the methods below into your own method if you need different sequence
        recursively_merge_adjacent_elements!(kramdown_tree)
        recursively_clean_up_nested_ems!(kramdown_tree) # has to be called after process_temp_em_class
        recursively_push_out_whitespace!(kramdown_tree)
        # needs to run after whitespace has been pushed out so that we won't
        # have a leading \t inside an :em that is the first child in a para.
        # After whitespace is pushed out, the \t will be a direct :text child
        # of :p and first char will be easy to detect.
        recursively_sanitize_whitespace_during_import!(kramdown_tree)
        # merge again since we may have new identical siblings after all the
        # other processing.
        recursively_merge_adjacent_elements!(kramdown_tree)
        recursively_clean_up_tree!(kramdown_tree)
        # Run this again since we may have new locations with leading or trailing whitespace
        recursively_sanitize_whitespace_during_import!(kramdown_tree)
        # merge again since we may have new identical siblings after cleaning up the tree
        # e.g. an italic span with whitespace only between two text nodes was removed.
        recursively_merge_adjacent_elements!(kramdown_tree)

        # DOCX import specific cleanup
        recursively_post_process_tree!(kramdown_tree)
      end

      # ***********************************************
      # Node type specific processors
      # ***********************************************

      def process_node_bookmarkend(xn)
        # bookmarkEnd
        ignore_node(xn)
        flag_match_found
      end

      def process_node_bookmarkstart(xn)
        # bookmarkStart
        ignore_node(xn)
        flag_match_found
      end

      def process_node_commentrangestart(xn)
        # commentRangeStart
        ignore_node(xn)
        flag_match_found
      end

      def process_node_commentrangeend(xn)
        # commentRangeEnd
        ignore_node(xn)
        flag_match_found
      end

      def process_node_commentreference(xn)
        # commentReference
        ignore_node(xn)
        flag_match_found
      end

      def process_node_del(xn)
        # Change tracking: Deletion. Ignore this node.
        # See process_node_ins.
        ignore_node(xn)
        flag_match_found
      end

      def process_node_hyperlink(xn)
        # hyperlink -> Pull
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      def process_node_ins(xn)
        # Change tracking: Insertion. Pull this node.
        # See process_node_del
        pull_node(xn)
        flag_match_found
      end

      def process_node_lastrenderedpagebreak(xn)
        # lastRenderedPageBreak
        ignore_node(xn)
        flag_match_found
      end

      def process_node_nobreakhyphen(xn)
        # TODO: How to handle noBreakHyphen
        # noBreakHyphen -> ?
        ignore_node(xn)
        flag_match_found
      end

      def process_node_omath(xn)
        # TODO: How to handle omath
        ignore_node(xn)
        flag_match_found
      end

      def process_node_p(xn)
        # Paragraph
        l = { :line => xn.line }
        p_style = xn.at_xpath('./w:pPr/w:pStyle')
        p_style_id = p_style ? p_style['w:val'] : nil
        case p_style_id
        when *paragraph_style_mappings.keys
          # A known paragraph style that we have a mapping for
          type, value, attr, options = paragraph_style_mappings[p_style_id]
          root = @ke_context.get('root', xn)
          return false  if !root
          para_ke = ElementRt.new(
            type,
            value,
            attr,
            if options.respond_to?(:call)
              { :location => l }.merge(options.call(xn))
            else
              { :location => l }.merge(options || {})
            end
          )
          root.add_child(para_ke)
          @ke_context.set('p', para_ke)
          @ke_context.with_text_container_stack(para_ke) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          # Hook to add specialized behavior in subclasses
          process_node_p_additions(xn, para_ke)
          @xn_context.process_children = false
        else
          raise(InvalidElementException, "Unhandled p_style_id #{ p_style_id.inspect }")
        end
        flag_match_found
      end

      def process_node_prooferr(xn)
        # proofErr (Word proofing error)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_ppr(xn)
        # pPr (paragraph properties)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_r(xn)
        # Text run
        trfas = TextRunFormatAttrs.new(xn)
        case trfas.applied_attrs
        when []
          # no attributes applied, pull node
          pull_node(xn)
        when [:italic]
          # italic with no other attributes -> markdown italics (*text*)
          em_el = Kramdown::ElementRt.new(:em)
          @ke_context.get_current_text_container(xn).add_child(em_el)
          @ke_context.with_text_container_stack(em_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when [:bold]
          # bold with no other attributes -> markdown strong (**text**)
          strong_el = Kramdown::ElementRt.new(:strong)
          @ke_context.get_current_text_container(xn).add_child(strong_el)
          @ke_context.with_text_container_stack(strong_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        else
          # em with classes added for each applied attribute
          em_el = Kramdown::ElementRt.new(:em, nil, { 'class' => trfas.applied_attrs.sort.join(' ') })
          @ke_context.get_current_text_container(xn).add_child(em_el)
          @ke_context.with_text_container_stack(em_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        end
        flag_match_found
      end

      def process_node_rpr(xn)
        # rPr (text_run properties)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_sectpr(xn)
        # sectPr
        ignore_node(xn)
        flag_match_found
      end

      def process_node_smarttag(xn)
        # smartTag -> Pull
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      def process_node_softhyphen(xn)
        # softHyphen -> Ignore, raise warning
        # Ignore for now, print a warning. There have been cases in the past
        # where translators intended to use a hyphen, however it ended up as a
        # softHyphen. Ignoring them would not be the expected behaviour.
        # Let's see how often it occurs.
        ignore_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      def process_node_t(xn)
        # This is a DOCX Text node, pull it and use the contained Nokogiri text node
        pull_node(xn)
        flag_match_found
      end

      def process_node_text(xn)
        # This is a Nokogiri text node
        @ke_context.add_text_to_current_text_container(xn.text, xn)
        flag_match_found
      end

      def process_node_tab(xn)
        # tab
        @ke_context.add_text_to_current_text_container("\t", xn)
        flag_match_found
      end

      # ***********************************************************
      # xml node processing helper methods
      # ***********************************************************

      # Capitalizes each word in string:
      # 'this IS a string to CAPITALIZE' => 'This Is A String To Capitalize'
      # @param [String] a_string
      def capitalize_each_word_in_string(a_string)
        a_string.split.map { |e| e.capitalize }.join(' ')
      end

      # Delete xn, send to deleted_text, children won't be processed
      # @param [Nokogiri::XML::Node] xn
      # @param [Boolean] send_to_deleted_text whether to send node's text to deleted_text
      # @param [Boolean] send_to_notes whether to send node's text to notes
      def delete_node(xn, send_to_deleted_text, send_to_notes)
        @xn_context.process_children = false
        add_deleted_text(xn, xn.text)  if send_to_deleted_text
        add_notes(xn, "Deleted text: #{ xn.text }")  if send_to_notes
      end

      # Call this from xn processing methods where we want to record that a match
      # has been found. This is used so that we can raise a warning for any
      # unhandled XML nodes.
      def flag_match_found
        @xn_context.match_found = true
      end

      # Ignore xn, don't send to deleted_text, children won't be processed
      # @param [Nokogiri::XML::Node] xn
      def ignore_node(xn)
        @xn_context.process_children = false
      end

      # Lowercases text contents of xn: 'TestString ALLCAPS' => 'teststrings allcaps'
      # @param [Nokogiri::XML::Node] xn
      def lowercase_node_text_contents!(xn)
        xn.children.each { |xnc|
          if xnc.text?
            xnc.content = xnc.content.unicode_downcase
          else
            add_warning(
              xn,
              "lowercase_node_text_contents was called on node that contained non-text children: #{ xn.name_and_class }"
            )
          end
        }
      end

      # Pull xn, Replacing self with children. Xml tree recursion will process children.
      # @param [Nokogiri::XML::Node] xn
      def pull_node(xn)
        # nothing to do with node
      end

      # Deletes a_string from xn and all its descendant nodes.
      # @param [String, Regexp] search_string_or_regex a string or regex for finding
      # @param [String] replace_string the replacement string
      # @param [Nokogiri::XML::Node] xn
      def replace_string_inside_node!(search_string_or_regex, replace_string, xn)
        if xn.text? && '' != xn.text && !xn.text.nil?
          xn.content = xn.text.gsub(search_string_or_regex, replace_string)
        else
          xn.children.each { |child_xn|
            replace_string_inside_node!(search_string_or_regex, replace_string, child_xn)
          }
        end
      end

      # Raises a warning and returns false if xn contains any text content other
      # than whitespace.
      # @param [Nokogiri::XML::Node] xn
      def verify_only_whitespace_is_present(xn)
        verify_text_matches_regex(xn, /\A[ \n]*\z/, 'contained non-whitespace')
      end

      def verify_text_matches_regex(xn, regex, warning_text)
        t = xn.text.strip
        if(t =~ regex)
          true
        else
          add_warning(
            xn,
            "#{ xn.name_and_class } #{ warning_text }: #{ t.inspect }"
          )
          false
        end
      end

      # Delegate instance method to class method
      def paragraph_style_mappings
        self.class.paragraph_style_mappings
      end

      # Hook for specialized behavior in sub classes.
      # @param xn [Nokogiri::XmlNode] the p XML node
      # @param ke [Kramdown::Element] the p kramdown element
      def process_node_p_additions(xn, ke)
        # Nothing to do. Override this method in specialized subclasses.
      end

      # Recursively post processes tree under ke.
      # Hook for specialized behavior in sub classes.
      # @param [Kramdown::Element] ke
      def recursively_post_process_tree!(ke)
        # Nothing to do
      end

    end
  end
end
