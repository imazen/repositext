# -*- coding: utf-8 -*-

require 'zip'
require 'nokogiri'
require 'repositext/parser/idml_story'
require 'kramdown/document'

module Repositext
  module Parser

    # Open an IDML file and parse all story files within with the Kramdown::Parser::IDMLStory parser.
    class IDML

      class Exception < RuntimeError; end

      # The name of the file from which the data was read.
      attr_reader :filename

      def initialize(filename)
        @filename = filename
        read_story_filenames
      end

      def story_names
        @stories.keys
      end

      def parse(names = self.story_names)
        data = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        data << '<idPkg:Story xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging" DOMVersion="8.0">'

        names.each do |name|
          raise Exception.new("Unknown story name #{name}") unless @stories.has_key?(name)
          data << get_stories(name).to_s
        end

        data << '</idPkg:Story>'
        Kramdown::Document.new(data, :input => 'IDMLStory')
      end

      private

      def read_story_filenames
        @stories = {}
        Zip::File.open(@filename, false) do |zip|
          data = zip.get_entry('designmap.xml').get_input_stream.read
          xml = Nokogiri::XML(data) {|cfg| cfg.noblanks}
          xml.xpath('/Document/idPkg:Story').each do |story|
            story_file = story['src']
            story_data = zip.get_entry(story_file).get_input_stream.read
            story_xml = Nokogiri::XML(story_data) {|cfg| cfg.noblanks}
            story_xml.xpath('/idPkg:Story/Story').each do |s|
              @stories[s['Self']] = story_file
            end
          end
        end
      rescue
        raise Exception.new($!)
      end

      def get_stories(name)
        Zip::File.open(@filename, false) do |zip|
          story_data = zip.get_entry(@stories[name]).get_input_stream.read
          story_xml = Nokogiri::XML(story_data) {|cfg| cfg.noblanks}
          story_xml.xpath('/idPkg:Story/Story')
        end
      end

    end

  end
end
