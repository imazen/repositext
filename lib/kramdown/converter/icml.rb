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
          :output_file_name => "icml_output.icml",
          :template_file_name => "../../../data/icml_template.erb",
          :template_string => ''
        }.merge(options)
      end

      # Writes an ICML file to disk (using @options[:output_file_name]).
      # Contains a single story that is based on root.
      # @param[Kramdown::Element] root the kramdown root element
      # @return ???
      def convert(root)
        story_xml = compute_story_xml(root)
        erb_template = compute_erb_template(options[:template_file_name], options[:template_string])
        write_file(story_xml, erb_template, options[:output_file_name])
      end

    protected

      # Returns IDMLStory XML for root
      # @param[Kramdown::Element] root the root element
      # @return[String] the story XML as string
      def compute_story_xml(root)
        xml_string, _warnings = ::Kramdown::Converter::IdmlStory.convert(root, @options)
        xml_string
      end

      # Returns erb template. Uses template_string if given, falls back to
      # template_file_name.
      # @param[String] template_file_name
      # @param[String] template_string
      # @return[String] the erb template
      def compute_erb_template(template_file_name, template_string)
        if '' == template_string.to_s.strip
          # use file
          File.read(template_file_name)
        else
          # use template_string
          template_string
        end
      end

      # Write ICML to file on disk
      # @param[String] story_xml the story xml. Will be inserted into template
      #     at XPATH ...
      # @param[String] erb_template the erb template
      # @param[String] output_file_name a full path to the output file
      def write_file(story_xml, erb_template, output_file_name)
        erb = ERB.new(erb_template)
        File.open(output_file_name, 'w').do |f|
          f << erb.result
        end
      end

    end
  end
end
