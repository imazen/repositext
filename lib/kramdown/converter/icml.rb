# -*- coding: utf-8 -*-

module Kramdown
  module Converter
    class Icml < Base

      # Create an ICML converter with the given options.
      # @param[Kramdown::Element] root
      # @param[Hash, optional] options
      def initialize(root, options = {})
        super
        @options = {
          :output_file => File.new("icml_output.icml", 'w'),
          :template_file => File.new(File.expand_path("../../../../data/icml_template.erb", __FILE__), 'r')
        }.merge(options)
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
        xml_string, _warnings = ::Kramdown::Converter::IdmlStory.convert(root, @options)
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
