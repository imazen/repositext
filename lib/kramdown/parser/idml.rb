# -*- coding: utf-8 -*-

require 'zip'
require 'nokogiri'
require 'ostruct'
require 'kramdown/parser/idml_story'
require 'kramdown/document'

module Kramdown
  module Parser

    # Open an IDML file and parse all story files within with the Kramdown::Parser::IDMLStory parser.
    class IDML

      class Exception < RuntimeError; end

      # The name of the file from which the data was read.
      attr_reader :filename, :stories

      def initialize(filename)
        @filename = filename
        @stories = extract_stories
      end

      # Returns the stories we want to import by default. Typically
      # the longest story in the IDML file.
      # @return[Array<OpenStruct>] array of story objects to be imported
      def stories_to_import
        [@stories.max_by { |e| e.length }]
      end

      # @param[Array<Story>] stories the stories to import. Defaults to story_to_import.
      def parse(stories = self.stories_to_import)
        data = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        data << '<idPkg:Story xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging" DOMVersion="8.0">'

        stories.each do |story|
          data << story.body
        end

        data << '</idPkg:Story>'
        Kramdown::Document.new(data, :input => 'IDMLStory')
      end

    private

      # Extracts story names from @filename
      # @return[Array<OpenStruct>] an array with story objects. See `get_story` for details.
      def extract_stories
        stories = []
        Zip::File.open(@filename, false) do |zipped_files|
          design_map_data = zipped_files.get_entry('designmap.xml').get_input_stream.read
          design_map_xml = Nokogiri::XML(design_map_data) { |cfg| cfg.noblanks }
          design_map_xml.xpath('/Document/idPkg:Story').each do |design_map_story_xml|
            story_src = design_map_story_xml['src']
            pkg_story_data = zipped_files.get_entry(story_src).get_input_stream.read
            pkg_story_xml = Nokogiri::XML(pkg_story_data) { |cfg| cfg.noblanks }
            pkg_story_xml.xpath('/idPkg:Story/Story').each do |story_xml|
              name = story_xml['Self']
              body = story_xml.to_s
              stories << OpenStruct.new(:name => name, :body => body, :length => body.length)
            end
          end
        end
        stories
      rescue
        raise Exception.new($!)
      end

    end

  end
end
