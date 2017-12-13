module Kramdown
  module Parser
    # A customized parser for validation purposes. It has the following modifications
    # from Kramdown::Parser::IdmlStory:
    #
    # * Adds validation to parsing, both at parse and update_tree time.
    class IdmlStoryValidation < Kramdown::Parser::IdmlStory

      # Add validation related i_vars to parser
      def parse
        @validation_errors = @options['validation_errors']
        @validation_warnings = @options['validation_warnings']
        @validation_file_descriptor = @options['validation_file_descriptor']
        @validation_logger = @options['validation_logger']

        xml = Nokogiri::XML(@source) { |cfg| cfg.noblanks }

        xml.xpath('/idPkg:Story/Story').each do |story|
          with_stack(@root, story) { parse_story(story) }
        end
        update_tree
      end

      # Validation hook that is called during parsing for each [...]StyleRange.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      # @param [Nokogiri::Xml::Node] xml_node the currently parsed idml node
      def validation_hook_during_parsing(kd_el, xml_node)
        case xml_node.name
        when 'ParagraphStyleRange'
          validate_presence_of_paragraph_style(kd_el, xml_node)
        when 'CharacterStyleRange'
          validate_presence_of_character_style(kd_el, xml_node)
        else
          puts "Unknown name: #{ xml_node.name}"
        end
        log_removal_of_element(kd_el, xml_node)
      end

      # Validation hook that is called during update_tree for each element.
      # At this point we don't have access to the source XML Nodes any more.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      def validation_hook_during_update_tree(kd_el)
        return true  unless kd_el
        validate_whitelisted_kramdown_features(kd_el)
        validate_whitelisted_class_names(kd_el)
      end

    protected

      # Validates that CharacterStyleRange does not have character style
      # '[No character style]'.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      # @param [Nokogiri::Xml::Node] xml_node the currently parsed idml node
      def validate_presence_of_character_style(kd_el, xml_node)
        if 'CharacterStyle/$ID/[No character style]' == xml_node['AppliedCharacterStyle']
          @validation_errors << ::Repositext::Validation::Reportable.error(
            {
              filename: @validation_file_descriptor,
              line: xml_node.line,
              context: sprintf("story %5s", story_name_for_xml_node(xml_node)),
            },
            [
              'Invalid character style',
              "'CharacterStyle/$ID/[No character style]'"
            ]
          )
        end
      end

      # Validates that ParagraphStyleRange does not have character style
      # '[No paragraph style]'.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      # @param [Nokogiri::Xml::Node] xml_node the currently parsed idml node
      def validate_presence_of_paragraph_style(kd_el, xml_node)
        if 'ParagraphStyle/$ID/[No paragraph style]' == xml_node['AppliedParagraphStyle']
          @validation_errors << ::Repositext::Validation::Reportable.error(
            {
              filename: @validation_file_descriptor,
              line: xml_node.line,
              context: sprintf("story %5s", story_name_for_xml_node(xml_node)),
            },
            [
              'Invalid paragraph style',
              "'ParagraphStyle/$ID/[No paragraph style]'"
            ]
          )
        end
      end

      # Validates that only whitelisted kramdown features are used.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      def validate_whitelisted_kramdown_features(kd_el)
        if !::Repositext::Validation::Validator::KramdownSyntaxAt.whitelisted_kramdown_features.include?(kd_el.type)
          st, li = (lo = kd_el.options[:location]) && lo.values_at(:story, :line)
          @validation_errors << Reportable.error(
            {
              filename: @validation_file_descriptor,
              line: li,
              context: sprintf("story %5s", st),
            },
            ['Invalid kramdown feature', ":#{ kd_el.type }"]
          )
        end
      end

      # Validates that only whitelisted class names are used.
      # @param [Kramdown::Element] kd_el the kramdown element for xml_node
      def validate_whitelisted_class_names(kd_el)
        # TODO: flesh out :block vs. :span context detection. This is very crude.
        context = case kd_el.type
        when :p, :record_mark, :header, :hr
          :block
        when :em, :strong
          :span
        when :gap_mark, :root, :subtitle_mark, :text
          # These don't have classes
          return true
        else
          raise "Handle this element type: #{ kd_el.type.inspect }"
        end
        whitelisted_class_names = ::Repositext::Validation::Validator::KramdownSyntaxAt.whitelisted_class_names.find_all { |e|
          e[:allowed_contexts].include?(context)
        }.map { |e| e[:name] }
        if (
          (klasses = kd_el.attr['class']) &&
          klasses.split(' ').any? { |k| !whitelisted_class_names.include?(k) }
        )
          st, li = (lo = kd_el.options[:location]) && lo.values_at(:story, :line)
          @validation_errors << ::Repositext::Validation::Reportable.error(
            {
              filename: @validation_file_descriptor,
              line: li,
              context: sprintf("story %5s", st),
            },
            ['Invalid class name', "#{ klasses }", "on element #{ kd_el.type}"]
          )
        end
      end

      # Raises a warning about removal of certain elements
      def log_removal_of_element(kd_el, xml_node)
        xml_node.children.each do |child|
          case child.name
          when 'Properties', 'HyperlinkTextDestination'
            @validation_logger.log_debug_info(
              [
                @validation_file_descriptor,
                sprintf("story %5s", story_name_for_xml_node(xml_node)),
                sprintf("line %5s", xml_node.line)
              ],
              ['Discarding Element', child.name]
            )
          end
        end
      end

      def story_name_for_xml_node(xml_node)
        xml_node.ancestors('Story').first['Self']
      end

    end
  end
end
