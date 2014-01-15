=begin

Importing Folio XML files to AT
===============================

* css is case insensitive
* 4 output sinks: AT, editors_notes, warnings, deleted_text

* pull an element
* delete an element and children
* delete certain characters, pull element

* checks on elements (compare to parent_record)
* compare with other records in tape (p.referenceline)

* add attrs to parent_record's IAL
* translate CSS class to another one (.Paragraph => .pn)
* look at children to decide on class (p with child span.pn => p.normal_pn)
* add class to parent paragraph
* choose class depending on element inline style

* wrap text in markdown syntax (e.g., italics: *..*)
* replace a span with horizontal rule, verify text contents

* first note within record.tape: save to editors_notes
* merge split elements

Types of actions
----------------

* traverse tree
* modify text contents
* pull element
* drop element
* add warning
* add editors note
* add deleted text
* add css class
* compare element with other elements (parent, record, paragraph, other elements in tape)
* add attrs to record IAL
* map_css_classes
* wrap text in markdown syntax
* detect if self is first note in record.tape, add_editors_note
* merge split events

=end

# Converts folio per tape XML files to AT kramdown files
#
# Parsing rules are documented here: https://docs.google.com/document/d/1vVVZ6HmRpr8c6WRpwCvQ9OXJzkKrc_AgzWQURHRSLX4/edit
#
require 'nokogiri'
require 'kramdown/document'

module Kramdown
  module Parser

    # Open a per tape Folio XML file and parse all record entries to kramdown.
    class Folio

      # @param[String] folio_xml
      # @param[Hash, optional] options these will be passed to Kramdown::Parser
      def initialize(folio_xml, options = {})
        @folio_xml = folio_xml
        @options = {
          :line_width => 100000, # set to very large value so that each para is on a single line
          :input => :repositext # that is what we generate as string below
        }.merge(options)
      end

      # Returns AT kramdown and other related documents as Hash of Strings
      # @return[Hash<String>] A hash with the following elements: Keys are the
      #     corresponding file names, values are each document as string.
      #     * 'folio.at': kramdown file imported from folio.xml
      #     * 'folio.deleted_text.json': text that was deleted while importing folio.xml
      #     * 'folio.editors_notes.json': editors notes that were extracted while importing folio.xml
      #     * 'folio.warnings.json': warnings that were raised while importing folio.xml
      def parse
        docs = convert_xml_to_kramdown(@folio_xml)
      end

    private

      # @param[String] xml
      # @return[Hash<String>] A hash with the following elements: Keys are the
      #     corresponding file names, values are each document as string.
      #     * 'folio.at': kramdown file imported from folio.xml
      #     * 'folio.deleted_text.json': text that was deleted while importing folio.xml
      #     * 'folio.editors_notes.json': editors notes that were extracted while importing folio.xml
      #     * 'folio.warnings.json': warnings that were raised while importing folio.xml
      def convert_xml_to_kramdown(xml)
        # Collectors for output sinks
        @kramdown_root = ElementFi.new(:root, nil, nil, :encoding => 'UTF-8')
        @folio_deleted_text = []
        @folio_editors_notes = []
        @folio_warnings = []
        xml_doc = Nokogiri::XML(xml)
        xml_doc.css('record').each do |any_record|
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
            tape_level_record = ElementFi.new(
              :record_mark, nil, { 'class' => 'rid', 'id' => "f-#{ tape_id }" }
            )
            @kramdown_root.add_child(tape_level_record)
            title = any_record.at_css('span.TapeTitle').text.strip.gsub(/\s+/, ' ')
            header_el = ElementFi.new(:header, nil, nil, :level => 1, :raw_text => title)
            header_el.add_child(ElementFi.new(:text, title))
            tape_level_record.add_child(header_el)
          when ["NormalLevel", nil]
            # paragraph level record
            para_level_record = ElementFi.new(
              :record_mark, nil, { 'class' => 'rid', 'id' => "f-#{ record_id }" }
            )
            @kramdown_root.add_child(para_level_record)
            any_record.css('> p').each do |para|
              extract_text_from_para_el(para, para_level_record)
            end
          else
            raise [klass, level].inspect
          end
        end
        kramdown_doc = Kramdown::Document.new('', @options)
        kramdown_doc.root = @kramdown_root
        {
          'folio.at' => kramdown_doc.to_kramdown,
          'folio.deleted_text.json' => @folio_deleted_text.to_json,
          'folio.editors_notes.json' => @folio_editors_notes.to_json,
          'folio.warnings.json' => @folio_warnings.to_json,
        }
      end

      #
      # @param[Nokogiri::XML::Element] para_el
      # @param[Kramdown::ElementFi] para_record The para level record element
      def extract_text_from_para_el(para_el, para_record)
        # skip referenceline
        return  if 'referenceline' == para_el['class']
        para_text = ''
        para_el.children.each do |para_child|
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
              raise "Handle this para_child type: #{ para_child.inspect }\n para_el: #{ para_el.inspect }"
            end
          when Nokogiri::XML::Text
            para_text << ' ' + para_child.text.strip
          when Nokogiri::XML::Comment
            # discard
          else
            raise "Handle this node type: #{ para_child.inspect }\n para_el: #{ para_el.inspect }"
          end
        end
        para_text = para_text.gsub(/\s+/, ' ').strip
        if '' != para_text
          pe = ElementFi.new(:p)
          pe.add_child(ElementFi.new(:text, para_text))
          para_record.add_child(pe)
        end
      end

      # @param[Nokogiri::XML::Element] el
      def own_text(el)
        el.xpath('text()').text
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

