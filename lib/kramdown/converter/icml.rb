# -*- coding: utf-8 -*-

module Kramdown
  module Converter
    class Icml < Base

      # Create an ICML converter with the given options.
      # @param [Kramdown::Element] root
      # @param [Hash, optional] options
      def initialize(root, options = {})
        super
        # NOTE: kramdown initializes all options with default values. So
        # :template_file is initialized to Nil. This breaks
        # @options = { <defaults> }.merge(options), so I have to set it like below.
        options[:template_file] ||= File.new(
          File.expand_path("../../../../templates/icml.erb", __FILE__),
          'r'
        )
        @options = options
      end

      def idml_story_converter
        ::Kramdown::Converter::IdmlStory
      end

      def paragraph_style_names
        ::Kramdown::Parser::IdmlStory.paragraph_style_mappings.keys
      end

      def character_style_names
        ::Kramdown::Parser::IdmlStory::HANDLED_CHARACTER_STYLES.map { |e|
          e.gsub('CharacterStyle/', '')
        }
      end

      # Writes an ICML file to IO (using @options[:output_file]).
      # Contains a single story that is based on root.
      # @param [Kramdown::Element] root the kramdown root element
      # @return ???
      def convert(root)
        story_xml = compute_story_xml(root)
        erb_template = options[:template_file].read
        render_output(story_xml, erb_template)
      end

    protected

      # Returns IDMLStory XML for root
      # @param [Kramdown::Element] root the root element
      # @return [String] the story XML as string
      def compute_story_xml(root)
        xml_string, _warnings = idml_story_converter.convert(root, @options)
        xml_string
      end

      # Return ICML as string
      # @param [String] story_xml the story xml. Will be inserted into template.
      # @param [String] erb_template the erb template
      def render_output(story_xml, erb_template)
        # assign i_vars referenced in template file
        @story = story_xml
        @character_style_names = character_style_names
        @paragraph_style_names = paragraph_style_names

        erb = ERB.new(erb_template, 0, '>')
        erb.result(binding)
      end

    end
  end
end
