# -*- coding: utf-8 -*-

# NOTE: This is WIP. I started implementing this and stopped just before we
# had to implement templating for all the files involved. We decided to start
# with a single file ICML conversion first.
# TODO: implement templates for all the files other than the story file
#       (see collect_files_for_archive method)
module Kramdown
  module Converter
    class Idml < Base

      # Create an IDML converter with the given options.
      # @param [Kramdown::Element] root
      # @param [Hash{Symbol => Object}] options
      def initialize(root, options = {})
        super
        @options = {
          :output_file => File.new("idml_output.idml", 'w')
        }.merge(options)
        configure_rubyzip
      end

      # Writes an IDML file to disk (using @options[:output_file_name]).
      # Contains a single story that is based on root.
      # @param [Kramdown::Element] root the kramdown root element
      # @return ???
      def convert(root)
        story_xml = compute_story_xml(root)
        files = collect_files_for_archive(story_xml)
        create_zip_archive(options[:output_file], files)
      end

    protected

      def configure_rubyzip
        Zip.setup do |c|
          c.continue_on_exists_proc = true # overwrite existing ZIP archives when compressing
          c.unicode_names = true
        end
      end

      # Returns IDMLStory XML for root
      # @param [Kramdown::Element] root the root element
      # @return [String] the story XML as string
      def compute_story_xml(root)
        xml_string, _warnings = ::Kramdown::Converter::IdmlStory.convert(root, @options)
        xml_string
      end

      # Builds array of all files to go into ZIP archive
      # @param [String] story_xml
      # @return [Array<Array>] Array of tuples (file_name and file_contents)
      def collect_files_for_archive(story_xml)
        [
          ['mimetype', 'application/vnd.adobe.indesign-idml-package'],
          # META-INF is optional
          # http://wwwimages.adobe.com/www.adobe.com/content/dam/Adobe/en/devnet/indesign/sdk/cs6/idml/idml-specification.pdf
          # Appendix A, 1.4.6 (p. 401)
          ['META-INF/container.xml', ""],
          ['META-INF/metadata.xml', ""],
          ['designmap.xml', ""],
          ['MasterSpreads/MasterSpread_A.xml', ""],
          ['Resources/Fonts.xml', ""],
          ['Resources/Graphic.xml', ""],
          ['Resources/Preferences.xml', ""],
          ['Resources/Styles.xml', ""],
          ['Spreads/Spread_spread1.xml', ""],
          ['Spreads/Spread_spread2.xml', ""],
          ['Stories/Story_story0.xml', story_xml],
          ['XML/BackingStory.xml', ""],
          ['XML/Mapping.xml', ""],
          ['XML/Tags.xml', ""]
        ]
      end

      # Writes a ZIP archive to disk
      # @param [IO] zip_archive_file an IO object
      # @param [Array<Array>] files the files to include in archive. Tuple of name and contents.
      def create_zip_archive(zip_archive_file, files)
        Zip::OutputStream.open(zip_archive_file) { |io|
          files.each do |(file_name, contents)|
            io.put_next_entry(file_name)
            io.write(contents)
          end
        }
      end

    end
  end
end
