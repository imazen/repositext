# -*- coding: utf-8 -*-

module Kramdown
  module Parser

    # Open an IDML file and parse all story files within with the Kramdown::Parser::IdmlStory parser.
    class Idml

      class Exception < RuntimeError; end

      attr_reader :stories

      # Override this to use different default options
      def default_options
        {
          :line_width => 100000, # set to very large value so that each para is on a single line
          :input => 'IdmlStory' # that is what we generate as string below
        }
      end

      # @param zip_file_contents [String]
      # @param options [Hash, optional] these will be passed to Kramdown::Parser
      def initialize(zip_file_contents, options = {})
        @zip_file_contents = zip_file_contents
        @options = default_options.merge(options)
        @stories = extract_stories
      end

      # Returns the stories we want to import by default. Typically
      # the longest story in the IDML file.
      # @return[Array<OpenStruct>] array of story objects to be imported
      def stories_to_import
        [@stories.max_by { |e| length_of_story_text_without_markup(e.body) }]
      end

      # @param[Array<Story>] stories the stories to import. Defaults to story_to_import.
      # @return[Kramdown::Document]
      def parse(stories = self.stories_to_import)
        data = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        data << '<idPkg:Story xmlns:idPkg="http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging" DOMVersion="8.0">'

        stories.each do |story|
          data << story.body
        end

        data << '</idPkg:Story>'
        Kramdown::Document.new(data, @options)
      end

    private

      # Extracts story names from @zip_file_contents
      # @return[Array<OpenStruct>] an array with story objects. See `get_story` for details.
      def extract_stories
        s = []
        Zip::File.open_buffer(@zip_file_contents) do |zipped_files|
          design_map_data = zipped_files.get_entry('designmap.xml').get_input_stream.read
          design_map_xml = Nokogiri::XML(design_map_data) { |cfg| cfg.noblanks }
          design_map_xml.xpath('/Document/idPkg:Story').each do |design_map_story_xml|
            story_src = design_map_story_xml['src']
            pkg_story_data = zipped_files.get_entry(story_src).get_input_stream.read
            pkg_story_xml = Nokogiri::XML(pkg_story_data) { |cfg| cfg.noblanks }
            pkg_story_xml.xpath('/idPkg:Story/Story').each do |story_xml|
              name = story_xml['Self']
              body = story_xml.to_s
              s << OpenStruct.new(:name => name, :body => body)
            end
          end
        end
        s
      rescue
        raise Exception.new($!)
      end

      # Returns text only for story_xml. Used to find primary story.
      # @[String] story_xml
      def length_of_story_text_without_markup(story_xml)
        xml_doc = Nokogiri::XML(story_xml) { |cfg| cfg.noblanks }
        xml_doc.inner_text.gsub(/[[:space:]]+/, ' ').length
      end

    end

  end
end
