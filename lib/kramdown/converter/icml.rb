# -*- coding: utf-8 -*-

module Kramdown
  module Converter
    class Icml < Base

      # Create an ICML converter with the given options.
      # @param[Kramdown::Element] root
      # @param[Hash, optional] options
      def initialize(root, options = {})
        super
        # NOTE: kramdown initializes all options with default values. So
        # :output_file and :template_file are initialized to Nil. This breaks
        # @options = { <defaults> }.merge(options), so I have to set them like below.
        options[:output_file] ||= File.new("icml_output.icml", 'w')
        options[:template_file] ||= File.new(
          File.expand_path("../../../../templates/icml.erb", __FILE__),
          'r'
        )
        @options = options
      end

      def idml_story_converter
        ::Kramdown::Converter::IdmlStory
      end

      # Writes an ICML file to IO (using @options[:output_file]).
      # Contains a single story that is based on root.
      # @param[Kramdown::Element] root the kramdown root element
      # @return ???
      def convert(root)
        story_xml = compute_story_xml(root)
        erb_template = options[:template_file].read
        write_file(story_xml, erb_template, options[:output_file])
      end

    protected

      # Returns IDMLStory XML for root
      # @param[Kramdown::Element] root the root element
      # @return[String] the story XML as string
      def compute_story_xml(root)
        xml_string, _warnings = idml_story_converter.convert(root, @options)
        xml_string
      end

      # Write ICML to file on disk
      # @param[String] story_xml the story xml. Will be inserted into template.
      # @param[String] erb_template the erb template
      # @param[IO] output_file an IO object to write to
      def write_file(story_xml, erb_template, output_file)
        # assign i_vars referenced in template file
        @story = story_xml

        erb = ERB.new(erb_template)
        output_file.write(erb.result(binding))
      end

    end
  end
end
