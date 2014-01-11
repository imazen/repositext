=begin
Extracts the inventory of element names/types/classes and instance counts
for a set of Folio per tape xml files

* iterate over all xml files
* parse each one
* walk the entire dom tree, extract name/type/class attrs for each element, count instances
* output as csv

Use like so:

require 'repositext/folio/folio_per_tape_xml_inventory'
i = Repositext::Folio::FolioPerTapeXmlInventory.new
i.extract
i.to_csv

=end

require 'nokogiri'

class Repositext
  class Folio
    class FolioPerTapeXmlInventory

      attr_accessor :inventory

      def initialize
        # path to folder that contains xml files, relative to this file's location
        @file_pattern = File.expand_path("../../../../../vgr-english/converted_folio/*.xml", __FILE__)
        @inventory = {}
        @file_count = 0
      end

      def extract
        Dir.glob(@file_pattern).find_all { |e| e =~ /\.xml$/}.each do |xml_file_name|
          puts xml_file_name
          @file_count += 1
          xml = File.read(xml_file_name)
          doc = Nokogiri::XML.parse(xml) { |cfg| cfg.noblanks }
          extract_data_from_node(doc.root)
        end
        nil
      end

      def to_csv
        puts "Extracted node inventory from #{ @file_count } XML files at #{ @file_pattern }"
        puts
        puts %w[name type class level instance_count].map { |e| e.capitalize }.join("\t")
        @inventory.each do |k,v|
          r = k
          r << v[:instance_count]
          puts r.join("\t")
        end
        nil
      end

    protected

      def extract_data_from_node(node)
        k = [node.name, node['type'], node['class'], node['level']]
        h = (@inventory[k] ||= { :instance_count => 0 })
        h[:instance_count] += 1
        node.children.each { |child_node| extract_data_from_node(child_node) }
      end

    end
  end
end
