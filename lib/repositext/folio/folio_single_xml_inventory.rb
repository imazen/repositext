=begin
Extracts the inventory of element names/types/classes and instance counts
for a Folio single xml file

* parse the xml file
* walk the entire dom tree, extract name/type/class attrs for each element, count instances
* output as csv

Use like so:

require 'repositext/folio/folio_single_xml_inventory'
i = Repositext::Folio::FolioSingleXmlInventory.new
i.extract
i.to_csv

=end

require 'nokogiri'

class Repositext
  class Folio
    class FolioSingleXmlInventory

      attr_accessor :inventory

      def initialize
        # path to folder that contains xml files, relative to this file's location
        @xml_file_names = [
          File.expand_path("../../../../../vgr-folioxml-supplementary/FFFs from NCH for NDJ 14-0108/MessageBeta the missing 17 tapes.xml", __FILE__),
          File.expand_path("../../../../../vgr-folioxml-supplementary/FFFs from NCH for NDJ 14-0108/MessageBeta all but 17 tapes.xml", __FILE__),
        ]
        @inventory = {}
      end

      def extract
        @xml_file_names.each do |xml_file_name|
          xml = File.read(xml_file_name)
          doc = Nokogiri::XML.parse(xml) { |cfg| cfg.noblanks }
          extract_data_from_node(doc.root)
        end
        nil
      end

      def to_csv
        puts "Extracted node inventory from XML file #{ @xml_file_name }"
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
        k = [
          node.name.downcase, node['type'], node['class'], node['level']
        ].map { |e| !!e ? e.downcase : nil }
        h = (@inventory[k] ||= { :instance_count => 0 })
        h[:instance_count] += 1
        node.children.each { |child_node| extract_data_from_node(child_node) }
      end

    end
  end
end
