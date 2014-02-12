=begin

Importing Folio XML files to AT
===============================

Naming conventions
------------------

* node: refers to a Nokogiri::XML::Node (XML space)
* element: refers to a Kramdown::Element (kramdown space). Note that we actually
  use a sub-class named Kramdown::ElementRt
* ke: l_var that refers to a kramdown element
* xn: l_var that refers to an XML node

=end

# Converts folio per tape XML files to AT kramdown files
#
require 'nokogiri'
require 'kramdown/document'

module Kramdown
  module Parser

    # Open a per tape Folio XML file and parse all record entries to kramdown.
    class Folio

      # @param[String] folio_xml
      # @param[Hash, optional] kramdown_options these will be passed to Kramdown::Parser
      def initialize(folio_xml, kramdown_options = {})
        @folio_xml = folio_xml
        @kramdown_options = {
          :line_width => 100000, # set to very large value so that each para is on a single line
          :input => 'KramdownRepositext' # that is what we generate as string below
        }.merge(kramdown_options)
      end

      # Override this method to change the conversion method name used to
      # generate the kramdown string.
      def kramdown_conversion_method_name
        :to_kramdown_repositext
      end

      # Returns AT kramdown and other related documents as Hash of Strings
      # @return[Hash<String>] A hash with the following elements: Keys are the
      #     corresponding file names, values are each document as string.
      #     * 'folio.at': kramdown file imported from folio.xml
      #     * 'folio.deleted_text.json': text that was deleted while importing folio.xml
      #     * 'folio.editors_notes.json': editors notes that were extracted while importing folio.xml
      #     * 'folio.data.json': data that was extracted while importing folio.xml
      #     * 'folio.warnings.json': warnings that were raised while importing folio.xml
      def parse
        # Initialize processing i_vars
        @data_output = {}
        @deleted_text_output = []
        # QUESTION: What do we call editors_notes?
        @editors_notes_output = []
        @warnings_output = []
        @ke_context = Folio::KeContext.new(
          { :root => Kramdown::ElementRt.new(:root, nil, nil, :encoding => 'UTF-8') },
          self
        )
        @xml_document = Nokogiri::XML(@folio_xml) # Can't do { |config| config.noblanks }, it breaks parsing

        # pre_process_xml_tree # not sure I need this...
        # Transform the XML tree
        @xml_document.css('record').each do |record_xn|
          process_xml_node(record_xn)
        end
        kramdown_doc = Kramdown::Document.new('', @kramdown_options)
        kramdown_doc.root = @ke_context.get('root', nil)
        post_process_kramdown_tree!(kramdown_doc.root)

        # Prepare return value
        kramdown_string = kramdown_doc.send(kramdown_conversion_method_name)
        kramdown_string = post_process_kramdown_string(kramdown_string)
        json_state = JSON::State.new(array_nl: "\n") # to format json output
        {
          'folio.at' => kramdown_string,
          'folio.data.json' => @data_output.to_json(json_state),
          'folio.deleted_text.json' => @deleted_text_output.to_json(json_state),
          'folio.editors_notes.json' => @editors_notes_output.to_json(json_state),
          'folio.warnings.json' => @warnings_output.to_json(json_state),
        }
      end

      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] key
      # @param[Object] value
      def add_data(xn, key, value)
        key = key.to_s
        case @data_output[key]
        when nil
          # Pristine key, just store value
          @data_output[key] = {
            'line' => xn.line,
            'path' => xn_name_and_class_path(xn),
            'value' => value
          }
        else
          # Key already contains a value. Raise an exception.
          # NOTE: I could store values as arrays and just append additional values
          raise(
            ArgumentError,
            "Multipe assignments to data[#{ key }] (#{ xn_name_and_class_path(xn) }, line #{ xn.line }"
          )
        end
      end
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] message
      def add_deleted_text(xn, message)
        if !message.nil? && '' != message
          @deleted_text_output << {
            message: message,
            line: xn.line,
            path: xn_name_and_class_path(xn)
          }
        end
      end
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] message
      def add_editors_notes(xn, message)
        if !message.nil? && '' != message
          @editors_notes_output << {
            message: message,
            line: xn.line,
            path: xn_name_and_class_path(xn)
          }
        end
      end
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] message
      def add_warning(xn, message)
        if !message.nil? && '' != message
          @warnings_output << {
            message: message,
            line: xn.line,
            path: xn_name_and_class_path(xn)
          }
        end
      end

    private

      # Processes an xml_node
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      def process_xml_node(xn)
        raise(ArgumentError, "xn cannot be nil")  if xn.nil?
        @xn_context = OpenStruct.new(
          :match_found => false,
          :process_children => true,
        )
        method_name = "process_node_#{ xn.name.downcase.gsub('-', '_') }"
        if respond_to?(method_name, true)
          self.send(method_name, xn)
        else
          raise "Unexpected element type #{ xn.name } on line #{ xn.line }. Requires method #{ method_name.inspect }."
        end
        if !@xn_context.match_found
          add_warning(xn, "Unhandled XML node #{ xn_name_and_class(xn) }")
        end
        # recurse over child XML Nodes
        if @xn_context.process_children
          xn.children.each { |xnc| process_xml_node(xnc) }
        end
      end

      # Modifies kramdown_tree in place
      # @param[Kramdown::Element] kramdown_tree the root of the tree
      def post_process_kramdown_tree!(kramdown_tree)
        # override this to post process elements in the kramdown tree
        # NOTE: It's important to call super if you override this method
        # for pushing out whitespace.

        # Recursively pushes out whitespace from :em
        # We do it here since all the layers of folio XML elements have been
        # peeled away and the problem is a lot easier to solve
        # @param[Kramdown::Element] ke the element to transform
        transformer = Proc.new { |ke|
          if [:em, :strong].include?(ke.type) && ke.children.any?
            if :text == ke.children.first.type && ke.children.first.value =~ /\A[ \n\t]+/
              # push out leading whitespace
              ke.children.first.value.lstrip!
              if(prev_sib = ke.previous_sibling).nil? || (:text != prev_sib.type)
                # previous sibling doesn't exist or is something other than :text
                # Insert a :text el as previous sibling
                ke.insert_sibling_before(Kramdown::ElementRt.new(:text, ' '))
              else
                # previous sibling is :text el
                # Append leading whitespace
                prev_sib.value << ' '
              end
            end
            if :text == ke.children.last.type && ke.children.last.value =~ /[ \n\t]+\z/
              # push out trailing whitespace
              ke.children.first.value.rstrip!
              if(foll_sib = ke.following_sibling).nil? || (:text != foll_sib.type)
                # following sibling doesn't exist or is something other than :text
                # Insert a :text el as followings sibling
                ke.insert_sibling_after(Kramdown::ElementRt.new(:text, ' '))
              else
                # following sibling is :text el
                # Prepend trailing whitespace
                foll_sib.value = ' ' + foll_sib.value
              end
            end
          end
          ke.children.each { |cke| transformer.call(cke) }
        }
        transformer.call(kramdown_tree)
      end

      # Performs post-processing on the kramdown string
      # @param[String] kramdown_string
      # @return[String] a modified copy of kramdown_string
      def post_process_kramdown_string(kramdown_string)
        # Collapse all whitespace to single spaces. Strip leading and trailing whitespace.
        kramdown_string.strip.gsub(/ +/, ' ') + "\n"
      end

      # ***********************************************
      # Node type specific processors
      # ***********************************************

      def process_node_bookmark(xn)
        pull_node(xn)
        flag_match_found
      end

      def process_node_br(xn)
        # br -> markdown line_break
        @ke_context.get_current_text_container(xn).add_child(Kramdown::ElementRt.new(:br))
        flag_match_found
      end

      def process_node_comment(xn)
        # comment -> delete
        delete_node(xn, true, false)
        flag_match_found
      end

      def process_node_infobase_meta(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_link(xn)
        pull_node(xn)
        flag_match_found
      end

      def process_node_mapping(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_note(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_object(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_object_def(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_p(xn)
        # p without class -> add regular p element
        rm = @ke_context.get('record_mark', xn)
        return false  if !rm
        p = Kramdown::ElementRt.new(:p)
        rm.add_child(p)
        @ke_context.set('p', p)
        @ke_context.with_text_container_stack(p) do
          xn.children.each { |xnc| process_xml_node(xnc) }
        end
        @xn_context.process_children = false
        flag_match_found
      end

      def process_node_popup(xn)
        pull_node(xn)
        flag_match_found
      end

      def process_node_record(xn)
        case [
          xn.name.downcase,
          (xn['class'] || '').downcase,
          (xn['level'] || '').downcase
        ]
        when ['record', 'normallevel', 'root']
          # record[level=root] -> drop element
          ignore_node(xn)
        when ['record', 'normallevel', '']
          # record.NormalLevel -> add :record_mark element
          para_level_record_mark = Kramdown::ElementRt.new(:record_mark)
          @ke_context.set('record_mark', para_level_record_mark)
          @ke_context.get('root', xn).add_child(para_level_record_mark)
        else
          return false # return early without calling flag_match_found
        end
        flag_match_found
      end

      def process_node_span(xn)
        c = (xn['class'] || '').downcase
        t = (xn['type'] || '').downcase
        case
        when 'bold' == t
          # span[type=bold] -> bold
          strong_el = Kramdown::ElementRt.new(:strong)
          @ke_context.get_current_text_container(xn).add_child(strong_el)
          @ke_context.with_text_container_stack(strong_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
        when 'italic' == t && '' == c
          # span[type=italic] -> markdown italics (*text*)
          em_el = Kramdown::ElementRt.new(:em)
          @ke_context.get_current_text_container(xn).add_child(em_el)
          @ke_context.with_text_container_stack(em_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        else
          return false # return early without calling flag_match_found
        end
        flag_match_found
      end

      def process_node_style_def(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_table(xn)
        # table, td, tr -> Pull for now, but issue warning
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      def process_node_td(xn)
        # table, td, tr -> Pull for now, but issue warning
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      def process_node_text(xn)
        @ke_context.add_text_to_current_text_container(xn.text, xn)
        flag_match_found
      end

      def process_node_tr(xn)
        # table, td, tr -> Pull for now, but issue warning
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      # ***********************************************************
      # xml node processing helper methods
      # ***********************************************************

      # Capitalizes each word in string:
      # 'this IS a string to CAPITALIZE' => 'This Is A String To Capitalize'
      # @param[String] a_string
      def capitalize_each_word_in_string(a_string)
        a_string.split.map { |e| e.capitalize }.join(' ')
      end

      # Delete xn, send to deleted_text, children won't be processed
      # @param[Nokogiri::XML::Node] xn
      # @param[Boolean] send_to_deleted_text whether to send node's text to deleted_text
      # @param[Boolean] send_to_editors_notes whether to send node's text to editors_notes
      def delete_node(xn, send_to_deleted_text, send_to_editors_notes)
        @xn_context.process_children = false
        add_deleted_text(xn, xn.text)  if send_to_deleted_text
        add_editors_notes(xn, "Deleted text: #{ xn.text }")  if send_to_editors_notes
      end

      # Deletes a_string from xn and all its descendant nodes.
      # @param[String, Regexp] search_string_or_regex a string or regex for finding
      # @param[String] replace_string the replacement string
      # @param[Nokogiri::XML::Node] xn
      def replace_string_inside_node!(search_string_or_regex, replace_string, xn)
        if xn.text? && '' != xn.text && !xn.text.nil?
          xn.content = xn.text.gsub(search_string_or_regex, replace_string)
        else
          xn.children.each { |child_xn|
            replace_string_inside_node!(search_string_or_regex, replace_string, child_xn)
          }
        end
      end

      # Call this from xn processing methods where we want to record that a match
      # has been found. This is used so that we can raise a warning for any
      # unhandled XML nodes.
      def flag_match_found
        @xn_context.match_found = true
      end

      # Ignore xn, don't send to deleted_text, children won't be processed
      # @param[Nokogiri::XML::Node] xn
      def ignore_node(xn)
        @xn_context.process_children = false
      end

      # Pull xn, Replacing self with children. Xml tree recursion will process children.
      # @param[Nokogiri::XML::Node] xn
      def pull_node(xn)
        # nothing to do with node
      end

      # Raises a warning and returns false if xn contains any text content other
      # than whitespace.
      # @param[Nokogiri::XML::Node] xn
      def verify_only_whitespace_is_present(xn)
        t = xn.text.strip
        if(t =~ /\A[ \n]*\z/)
          true
        else
          add_warning(
            xn,
            "#{ xn_name_and_class(xn) } contained non-whitespace: #{ t.inspect }"
          )
          false
        end
      end

      # Returns name and class of xn in CSS notation
      # @param[Nokogiri::XML::Element] el
      def xn_name_and_class(xn)
        [xn.name, xn['class']].compact.join('.')
      end

      def xn_name_and_class_path(xn, downstream_path = '')
        downstream_path = xn_name_and_class(xn) + downstream_path
        if xn.parent && !xn.parent.xml?
          # Recurse to parent unless it's the top level XML Document node (.xml?)
          xn_name_and_class_path(xn.parent, ' > ' + downstream_path)
        else
          # This is the top level node
          return downstream_path
        end
      end

    end
  end
end
