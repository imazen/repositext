require 'nokogiri'
require 'kramdown/document'

module Kramdown
  module Parser

    # Open a per tape Folio XML file and parse all record entries to kramdown.
    class Folio

      # The name of the file from which the data was read.
      attr_reader :filename

      def initialize(the_filename)
        @filename = the_filename
      end

      # Return kramdown as string
      def parse
        xml = File.read(@filename)
        kramdown = convert_xml_to_kramdown(xml)
      end

    private

      # @param[String] xml
      # @return[String] a kramdown doc
      def convert_xml_to_kramdown(xml)
        # NOTE: for now we just want plain text and record ids.
        kramdown = ''
        doc = Nokogiri::XML(xml)
        doc.css('record').each do |any_record|
          # extract record_ids
          year_id, tape_id, record_id = any_record['fullPath'].gsub(/\A\//, '').split('/')
          # extract differentiating features
          klass = any_record['class']
          level = any_record['level']
          case [klass, level]
          when ["NormalLevel", "root"]
            # root level record
            # Nothing to do
          when ["Year", "Year"]
            # year level record
            # Nothing to do
          when ["Tape", "Tape"]
            # tape level record
            kramdown << "\n\n^^^{:.rid #f-#{ tape_id }}"
            title = any_record.at_css('span.TapeTitle').text.strip.gsub(/\s+/, ' ')
            kramdown << "\n\n# #{ title }"
          when ["NormalLevel", nil]
            # paragraph level record
            kramdown << "\n\n^^^{:.rid #f-#{ record_id }}"
            any_record.css('> p').each do |para|
              extract_text_from_para_node(para, kramdown)
            end
          else
            raise [klass, level].inspect
          end
        end
        Kramdown::Document.new(kramdown.strip + "\n", :input => :repositext)
      end

      def extract_text_from_para_node(para_node, string_collector)
        # skip referenceline
        return  if 'referenceline' == para_node['class']
        para_text = ''
        para_node.children.each do |para_child|
          case para_child
          when Nokogiri::XML::Element
            case para_child.name
            when 'bookmark', 'note', 'span', 'br'
              # discard
            when 'link'
              # capture own_text for popup links
              if 'popup' == para_child['type']
                para_text << ' ' + own_text(para_child).strip
              end
            else
              raise "Handle this para_child type: #{ para_child.inspect }\n para_node: #{ para_node.inspect }"
            end
          when Nokogiri::XML::Text
            para_text << ' ' + para_child.text.strip
          when Nokogiri::XML::Comment
            # discard
          else
            raise "Handle this node type: #{ para_child.inspect }\n para_node: #{ para_node.inspect }"
          end
        end
        para_text = para_text.gsub(/\s+/, ' ').strip
        if '' != para_text
          string_collector << "\n\n"
          string_collector << para_text
        end
      end

      def own_text(node)
        node.xpath('text()').text
      end

    end
  end
end

# each time I call transformer.read, I get a new record.
# At that point I can decide if I need to start a new file, or append to current


# have plaintext and record_ids (f_xxx) for kramdown


# make sure that every p-tag is a separate paragraph


# Output:

# imazen/vgr-english/converted_folio/
#   xml and kramdown files side by side
#     65-1203.xml
#     65-12-3.at

# <record class="Tape" customHeading="true" fullPath="/47000009/47010009" groups="728 tapes - Folio is TR source,zzzz q000,zzz no audio -- no KPN,zz mm-04-april,zzzzz nch2003 tapes proofed with DSP for 03 release,zzzzz KAsent 5/2001,zzzzzzzzzzzz 2010,zzzzzzzzzzz 2010,zzz level records,zz 1947-1962,zz tapes,zz 1947,zz dd-07-saturday,zzzzz Para Style Applied -- ACTION" level="Tape" recordId="47010009">
#   <p style="margin-top:0.0291667in;">
#     <note height="3in" title="Tape Note" width="5in">
#     </note>
#     <span class="zzzPID" type="zzz PID">47010009</span>
#     <span class="zlevelrecordtapenumber" type="z level record tape number">
#       <span class="DateCode" type="Date Code">
#         <span type="recordHeading">47-0412</span>
#       </span>
#     </span>
#     <span type="recordHeading">
#       <span class="zlevelrecordtitle" type="z level record title">
#         <span class="TapeTitle" type="Tape Title">FAITH IS THE SUBSTANCE</span>
#       </span>
#       <span class="zlevelrecordlocation" type="z level record location">
#         <span class="Location" type="Location">OAKLAND CA</span>
#       </span>
#       <span class="Dayofweek" type="Day of week">
#         SATURDAY
#         <span class="referencelinetitlesuffix" type="characterstyle">_</span>
#       </span>
#       <span class="Time" type="Time">103</span>
#     </span>
#   </p>
