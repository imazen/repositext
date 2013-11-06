# -*- coding: utf-8 -*-
module Kramdown
  module Converter
    class Idml < Base

      # Create an IDML converter with the given options.
      # @param[Kramdown::Element] root
      # @param[Hash, optional] options
      def initialize(root, options = {})
        super
        @options = {
          :idml_output_file_name => "idml_output.idml"
        }.merge(options)
        configure_rubyzip
      end

      # Writes an IDML file to disk (using @options[:idml_output_file_name]).
      # Contains a single story that is based on root.
      # @param[Kramdown::Element] root the kramdown root element
      # @return ???
      def convert(root)
        story_xml = compute_story_xml(root)
        files = collect_files_for_archive(story_xml)
        create_zip_archive(options[:idml_output_file_name], files)
      end

    protected

      def configure_rubyzip
        Zip.setup do |c|
          c.on_exists_proc = true
          c.continue_on_exists_proc = true
          c.unicode_names = true
        end
      end

      # Returns IDMLStory XML for root
      # @param[Kramdown::Element] root the root element
      # @return[String] the story XML as string
      def compute_story_xml(root)
        xml_string = Kramdown::Converter::IdmlStory.convert(root, @options)
      end

      # Builds array of all files to go into ZIP archive
      # @param[String] story_xml
      # @return[Array<Array>] Array of tuples (file_name and file_contents)
      def collect_files_for_archive(story_xml)
        [
          ['theStory', story_xml]
        ]
      end

      # Writes a ZIP archive to disk
      # @param[String] zip_archive_file_name a complete path to the output file location and name
      # @param[Array<Array>] files the files to include in archive. Tuple of name and contents.
      def create_zip_archive(zip_archive_file_name, files)
        Zip::OutputStream.open(zip_archive_file_name) { |zos|
          files.each do |(file_name, contents)|
            zos.put_next_entry(file_name)
            zos.puts contents
          end
        }
      end

    end
  end
end
