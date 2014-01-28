=begin

Importing Folio XML files to AT
===============================

Workflow
--------

* validation:
  * check that text contents of all p.referenceline are identical
* first pass:
  * convert xml_nodes to kramdown_elements
    * add kramdown_element to kd
    * run through transforms, passing both xml_node + kd_el to matcher and transformer
* second pass:
  * walk entire kd_tree
    * merge disconnected elements
    * remove placeholder classes
    * set p.normal_pn etc. depending on an element's children
  * run tree-wide checks

Naming conventions
------------------

* node: refers to a Nokogiri::XML::Node (XML space)
* element: refers to a Kramdown::Element (kramdown space). Note that we actually
  use a sub-class named Kramdown::ElementRt
* ke: l_var that refers to a kramdown element
* xn: l_var that refers to an XML node

Items
-----

* css is case insensitive
* 4 output sinks: AT, editors_notes, warnings, deleted_text
* make sure that every p-tag is a separate paragraph

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
      # @param[Hash, optional] kramdown_options these will be passed to Kramdown::Parser
      def initialize(folio_xml, kramdown_options = {})
        @folio_xml = folio_xml
        @kramdown_options = {
          :line_width => 100000, # set to very large value so that each para is on a single line
          :input => :repositext # that is what we generate as string below
        }.merge(kramdown_options)
      end

      # Returns AT kramdown and other related documents as Hash of Strings
      # @return[Hash<String>] A hash with the following elements: Keys are the
      #     corresponding file names, values are each document as string.
      #     * 'folio.at': kramdown file imported from folio.xml
      #     * 'folio.deleted_text.json': text that was deleted while importing folio.xml
      #     * 'folio.editors_notes.json': editors notes that were extracted while importing folio.xml
      #     * 'folio.data.json': data that was extracted while importing folio.xml
      #     * 'folio.warnings.json': warnings that were raised while importing folio.xml
      def parse
        # Initialize processing i_vars
        @data_output = {}
        @deleted_text_output = []
        @editors_notes_output = []
        @warnings_output = []
        @ke_context = Folio::KeContext.new(
          { :root => Kramdown::ElementRt.new(:root, nil, nil, :encoding => 'UTF-8') },
          self
        )
        # TODO outside of traversing XML tree (either before or after, don't know yet):
        # * merge fragmented elements (caused by overlapping elements in Folio)
        # * span.SmCaps1, span.SmCaps2, span.zVGRScriptureSmallCaps -> span.smcaps (join subsequent elements, deduplicate classes).
        # * span.ScriptureComments, span.ScriptureParaphrase -> *no* italics. Ensure no italics are applied, even if there is an overlap with span.ScriptureReading or span.RedLetterScriptureReading. Use temporary placeholder class that will prevent merging of overlapping elements in second phase, then remove placeholder classes.
        # * record groups - Excluding the Tape level record, the intersection of all groups on all records should be added to the 'json' file. The remainder can be piped to the editors file. groups is an attribute of record element. key in json is ‘folio-record-groups’. Put after everything else in editors file.

        # pre_process_xml_tree # not sure I need this...
        # Transform the XML tree
        Nokogiri::XML(@folio_xml).css('record').each do |record_xn|
          process_xml_node(record_xn)
        end
        kramdown_doc = Kramdown::Document.new('', @kramdown_options)
        kramdown_doc.root = @ke_context.get('root', nil)
        post_process_kramdown_tree!(kramdown_doc.root)

        # Prepare return value
        kramdown_string = kramdown_doc.to_kramdown
        kramdown_string = post_process_kramdown_string(kramdown_string)
        json_state = JSON::State.new(array_nl: "\n") # to format json output
        {
          'folio.at' => kramdown_string,
          'folio.data.json' => @data_output.to_json(json_state),
          'folio.deleted_text.json' => @deleted_text_output.to_json(json_state),
          'folio.editors_notes.json' => @editors_notes_output.to_json(json_state),
          'folio.warnings.json' => @warnings_output.to_json(json_state),
        }
      end

      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] key
      # @param[Object] value
      def add_data(xn, key, value)
        key = key.to_s
        case @data_output[key]
        when nil
          # Pristine key, just store value
          @data_output[key] = {
            'line' => xn.line,
            'path' => xn_name_and_class_path(xn),
            'value' => value
          }
        else
          # Key already contains a value. Raise an exception.
          # NOTE: I could store values as arrays and just append additional values
          raise(
            ArgumentError,
            "Multipe assignments to data[#{ key }] (#{ xn_name_and_class_path(xn) }, line #{ xn.line }"
          )
        end
      end
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] message
      def add_deleted_text(xn, message)
        if !message.nil? && '' != message
          @deleted_text_output << {
            message: message,
            line: xn.line,
            path: xn_name_and_class_path(xn)
          }
        end
      end
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] message
      def add_editors_notes(xn, message)
        if !message.nil? && '' != message
          @editors_notes_output << {
            message: message,
            line: xn.line,
            path: xn_name_and_class_path(xn)
          }
        end
      end
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      # @param[String] message
      def add_warning(xn, message)
        if !message.nil? && '' != message
          @warnings_output << {
            message: message,
            line: xn.line,
            path: xn_name_and_class_path(xn)
          }
        end
      end

    private

      # Processes an xml_node
      # @param[Nokogiri::XML::Node] xn the XML Node to process
      def process_xml_node(xn)
        raise(ArgumentError, "xn cannot be nil")  if xn.nil?
        @xn_context = OpenStruct.new(
          :match_found => false,
          :process_children => true,
        )
        method_name = "process_node_#{ xn.name.downcase.gsub('-', '_') }"
        if respond_to?(method_name, true)
          self.send(method_name, xn)
        else
          raise "Unexpected element type #{ xn.name } on line #{ xn.line }. Requires method #{ method_name.inspect }."
        end
        if !@xn_context.match_found
          add_warning(xn, "Unhandled XML node #{ xn_name_and_class(xn) }")
        end
        # recurse over child XML Nodes
        if @xn_context.process_children
          xn.children.each { |xnc| process_xml_node(xnc) }
        end
      end

      # Modifies kramdown_tree in place
      # @param[Kramdown::Element] kramdown_tree the root of the tree
      def post_process_kramdown_tree!(kramdown_tree)
        # TODO: implement this
        # p (with child element span.pn) -> p.normal_pn
        # p (without child element span.pn) -> p.normal
      end

      # Performs post-processing on the kramdown string
      # @param[String] kramdown_string
      # @return[String] a modified copy of kramdown_string
      def post_process_kramdown_string(kramdown_string)
        # Collapse all whitespace to single spaces. Strip leading and trailing whitespace.
        kramdown_string.strip.gsub(/ +/, ' ') + "\n"
      end

      def process_node_bookmark(xn)
        # bookmark -> pull [The translator link/bookmark should be recreatable]
        pull_node(xn)
        flag_match_found
      end

      def process_node_br(xn)
        # br -> markdown line_break
        @ke_context.get_current_text_container(xn).add_child(Kramdown::ElementRt.new(:br))
        flag_match_found
      end

      def process_node_comment(xn)
        # comment -> delete
        delete_node(xn, true, false)
        flag_match_found
      end

      def process_node_infobase_meta(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_link(xn)
        c = (xn['class'] || '').downcase
        t = (xn['type'] || '').downcase
        case
        when 'jmbs' == c
          # link.JMBs -> Export contents of the link and the contents of the
          # 'program' attribute to the editors file. Flag as "DO NOT EDIT" in
          # the editors note. Add a record group "DNE" to the record’s IAL.
          # TODO: implement this
          @ke_context.set_attr_on_record_mark(xn, 'DNE', true)
        when 'program' == c
          # link.Program -> pull
          pull_node(xn)
        when 'tls' == c
          # link.TLS, span.TLS -> delete any instances of the † character (U+2020),
          # then pull the element.
          replace_string_inside_node!("†", '', xn)
          pull_node(xn)
        when 'popup' == t
          # link[type=popup] -> pull
          pull_node(xn)
        else
          # return without calling flag_match_found
          return false
        end
        flag_match_found
      end

      def process_node_mapping(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_note(xn)
        # note (first note within record.tape ) -> Save to editors notes and
        # json, parse using regex, put all attrs into array. Validate presence
        # of expected fields.
        # NOTE: this is implemented in process_node_record (tape)

        # All other notes go to editors_notes, they are treated like popups.
        delete_node(xn, false, true)
        flag_match_found
      end

      def process_node_object(xn)
        # QUESTION: what to do with object?
        # /vgr-english/import_folio/65/ENG65-1128e.xml
        # line 4246:
        # <object handler="Bitmap" name="eagles.bmp" src="MessageBeta all but 17 tapes.OB\FFF37.OB" style="width:1.0625in;height:0.677083in;" type="folio" />
        ignore_node(xn)
        flag_match_found
      end

      def process_node_object_def(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_p(xn)
        case (xn['class'] || '').downcase
        when ''
          # p without class -> add regular p element
          rm = @ke_context.get('record_mark', xn)
          return false  if !rm
          p = Kramdown::ElementRt.new(:p)
          rm.add_child(p)
          @ke_context.set('p', p)
          @ke_context.with_text_container_stack(p) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when 'action'
          # p.ACTION -> Delete Node and all contents, verify only whitespace is
          # present.
          verify_only_whitespace_is_present(xn)
          delete_node(xn, true, false)
        when 'levelrecordspokenwordbook'
          # p.levelrecordspokenwordbook -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'levelrecordtitleauxiliary'
          # p.levelrecordtitleauxiliary (inside record[level=tape]) -> json (alternate titles)
          # NOTE: this is implemented in process_node_record (tape)
        when 'quotespacing'
          # p.QuoteSpacing -> Assert that only whitespace is present -
          # and delete it and any children.
          verify_only_whitespace_is_present(xn)
          delete_node(xn, true, false)
        when 'referenceline', 'referencelinecab'
          # p.referenceline and p.referencelinecab -> Delete nodes and all contents.
          # Text contents should be identical across all records in a tape (excluding zzPID).
          # Warn if there is a discrepancy. Send to deleted_text only if there
          # is a discrepancy with siblings.
          @ke_context.record_distinct_reference_line_contents(xn.text, xn)
          delete_node(xn, false, false)
        when 'scripturereading'
          # p.scripturereading -> p.scr
          rm = @ke_context.get('record_mark', xn)
          return false  if !rm
          p = Kramdown::ElementRt.new(:p, nil, { 'class' => 'scr' })
          rm.add_child(p)
          @ke_context.set('p', p)
          @ke_context.with_text_container_stack(p) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when 'singing'
          # p.singing -> p.song (if previous paragraph is a song), otherwise p.stanza
          rm = @ke_context.get('record_mark', xn)
          return false  if !rm
          previous_p = @ke_context.get('p', xn) # we haven't updated ke_context.p yet, so it points to previous
          p = Kramdown::ElementRt.new(
            :p,
            nil,
            { 'class' => (previous_p && previous_p.has_class?('song')) ? 'song' : 'stanza' }
          )
          rm.add_child(p)
          @ke_context.set('p', p)
          @ke_context.with_text_container_stack(p) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        else
          return false # return early without calling flag_match_found
        end
        flag_match_found
      end

      def process_node_popup(xn)
        c = (xn['class'] || '').downcase
        case c
        when 'jmbs', 'popup'
          # popup.JMBs, popup.popup -> Export to editor notes file, remove contents.
          # Export the anchor text to editor notes as well, which is defined by
          # the parent link type="popup" element. Perhaps bold the anchor text to
          # separate it from the context. Include the parent record element.
          # Add a record group "DNE" to the record’s IAL (only popup.JMB).
          # TODO: implement this
          # call process_xml_node with special popup context so that we get into span(type=bold)?
          # @in_popup = true
          # process_xml_node(...)
          # @in_popup = false
          @ke_context.set_attr_on_record_mark(xn, 'DNE', true)  if 'jmbs' == c
          @xn_context.process_children = false
        else
          return false # return early without calling flag_match_found
        end
        flag_match_found
      end

      NOTE_DATA_TEXT_VAL_REGEXP = /[[:alnum:]\"\.\,\-\s]+[[:alnum:]\"\.\,\-]/
      NOTE_DATA_REGEXP = /
        \A
        \s*
        TAPE:\s?(?<tape>\d{2}-\d{4}\w?) # matches 47-0402 or 47-1100X
        \s+
        DATE:\s?(?<date>[[:alnum:],\s]+\d{4}) # matches NOVEMBER 17, 1947
        \s+
        QUOTES:\s*(?<quotes>\d+) # matches number of quotes
        \s+
        MINUTES:\s*(?<minutes>\d+) # matches number of questions
        \s+
        TITLE:\s?(?<title>#{ NOTE_DATA_TEXT_VAL_REGEXP }) # matches any text up to place
        \s+
        PLACE:\s?(?<place>#{ NOTE_DATA_TEXT_VAL_REGEXP }) # matches any text up to vee enn
        \s+
        (?<vee_enn>V-\s+N-) # matches hard coded string QUESTION do we need to record this?
        \s+
        NOTE:\s?(?<note>#{ NOTE_DATA_TEXT_VAL_REGEXP })? # matches any text up to tape quality
        \s+
        TAPE\sQUALITY:\s?(?<tape_quality>#{ NOTE_DATA_TEXT_VAL_REGEXP })
        \s*
        \z
      /x

      def process_node_record(xn)
        update_record_ids_in_ke_context(xn) # do this first so that we have up-to-date context
        case [
          xn.name.downcase,
          (xn['class'] || '').downcase,
          (xn['level'] || '').downcase
        ]
        when ['record', 'normallevel', 'root']
          # record[level=root] -> drop element
          ignore_node(xn)
        when ['record', 'year', 'year']
          # record[level=year] -> ?
          # QUESTION: what to do with year level records?
          ignore_node(xn)
        when ['record', 'tape', 'tape']
          # record.Tape[level=tape] -> Add :record_mark
          tape_id = @ke_context.get('tape_id', xn)
          tape_level_record_mark = Kramdown::ElementRt.new(
            :record_mark, nil, { 'class' => 'rid', 'id' => "f-#{ tape_id }" }
          )
          @ke_context.set('record_mark', tape_level_record_mark)
          @ke_context.get('root', xn).add_child(tape_level_record_mark)
          # note (first note within record.tape ) -> Save to editors notes and
          # json, parse using regex, put all attrs into array. Validate presence
          # of expected fields. All other notes go to editors file, they are
          # treated like popups.
          # Example note xml:
          # <note height="3in" title="Tape Note" width="5in">
          #   <p>
          #     TAPE: 47-1102
          #     <br/>
          #     DATE: SUNDAY AFTERNOON NOVEMBER 02, 1947
          #     <br/>
          #     QUOTES:
          #     <span class="zzquotes" type="zz quotes">51</span>
          #     <br/>
          #     MINUTES:
          #     <span class="Time" type="Time">71 </span>
          #     <br/>
          #     TITLE: THE ANGEL OF GOD
          #     <br/>
          #     PLACE: SHRINER TEMPLE, PHOENIX AZ
          #     <br/>
          #     V-   N-
          #     <br/>
          #     NOTE: CORRECTED FROM   47--1130
          #     <br/>
          #     TAPE QUALITY: Lots of static but mostly can be understood. Previously titled &quot;Angel and His Commission.&quot;
          #   </p>
          #   <p>VOGR.VGR</p>
          # </note>
          # TODO: validate presence of expected fields
          title_from_first_note = '' # for comparison further down
          xn.css('note').each_with_index do |note_xn, i|
            note_data = note_xn.css('p').inject({}) { |nd, p_xn|
              if(m1 = p_xn.content.match(NOTE_DATA_REGEXP))
                # found data
                %w[
                  tape date quotes minutes title place vee_enn note tape_quality
                ].each { |e| nd[e] = m1[e] }
                title_from_first_note = nd['title']
              elsif('VOGR.VGR' == p_xn.text.strip)
                # found marker string
                # QUESTION: what do we do with this?
              else
                # no match, raise warning
                add_warning(xn, "Couldn't match note data: #{ p_xn.text }")
              end
              nd
            }
            if 0 == i
              # Add first note to json
              add_data(note_xn, 'tape_note', note_data)
            end
            # add all notes to editors_notes
            add_editors_notes(note_xn, note_data.inspect)
          end

          # span.zlevelrecordtitle (inside record[level=tape]) -> h1
          # (after Camel casing from all caps). Compare this to the one we get
          # from the first note.
          header_el = Kramdown::ElementRt.new(:header, nil, nil, :level => 1)
          tape_level_record_mark.add_child(header_el)
          title_text = xn.at_css('span.zlevelrecordtitle').text || ''
          title_text = capitalize_each_word_in_string(title_text)
          text_el = Kramdown::ElementRt.new(:text, title_text)
          header_el.add_child(text_el)
          if(title_text.downcase != title_from_first_note.downcase)
            add_warning(xn, "Discrepancy in tape title: '#{ title_text }' -> '#{ title_from_first_note }'")
          end
          # p.levelrecordtitleauxiliary (inside record[level=tape]) -> json (alternate titles)
          if(p_xn = xn.at_css('p.levelrecordtitleauxiliary')) && p_xn.text
            add_data(xn, :alternate_title, p_xn.text.strip.gsub(/[\n\t ]+/, ' '))
          end
          @xn_context.process_children = false
        when ['record', 'normallevel', '']
          # record.NormalLevel -> add :record_mark element
          ri = @ke_context.get('record_id', xn)
          para_level_record_mark = Kramdown::ElementRt.new(
            :record_mark, nil, { 'class' => 'rid', 'id' => "f-#{ ri }" }
          )
          @ke_context.set('record_mark', para_level_record_mark)
          @ke_context.get('root', xn).add_child(para_level_record_mark)
        else
          return false # return early without calling flag_match_found
        end
        # Have to do this after I updated ke_context.record_mark
        if xn['groups'] && xn['groups'].downcase.index('jmbscans')
          # record[groups~=JMBscans] -> Add DNE flag.
          @ke_context.set_attr_on_record_mark(xn, 'DNE', true)
        end
        # QUESTION: remove immediate text nodes to eliminate "No text_container_stack present" warnings?
        xn.xpath('text()').each do |text_xn|
          if text_xn.content =~ /\A\s+\z/
            text_xn.remove
          end
        end
        flag_match_found
      end

      def process_node_span(xn)
        c = (xn['class'] || '').downcase
        t = (xn['type'] || '').downcase
        case
        when (xn['style'] || '') =~ /text-decoration:\s*underline/
          # span[style="text-decoration:underline;"] -> span.underline
          # (look at element style, some elements may have a type ‘underline’
          # but style ‘text-decoration:normal’, style overrides type. This may
          # also apply to italics and bold, ...)
          # TODO: implement this
        when 'background-color' == t
          # span[type=background-color]  -> pull
          pull_node(xn)
        when 'bold' == t
          # span[type=bold] -> bold (only used in popups/notes)
          # TODO: implement this
          # This occurs only in popups (and notes?). Those turn off recursion,
          # so we have to call this manually to process contained spans with type bold
        when 'font-family' == t
          # span[type=font-family] -> pull
          pull_node(xn)
        when 'font-size' == t
          # span[type=font-size] -> pull
          pull_node(xn)
        when 'foreground-color' == t
          # span[type=foreground-color] -> pull
          pull_node(xn)
        when 'highlighter' == t
          # span[type=highlighter] -> pull
          pull_node(xn)
        when 'italic' == t && '' == c
          # span[type=italic] -> markdown italics (*text*)
          # TODO: implement this
          # This occurs only in popups (and notes?). Those turn off recursion,
          # so we have to call this manually to process contained spans with type bold
        when 'datecode' == c
          # span.DateCode -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'editorsnotes' == c
          # span.EditorsNotes -> pull, after modifying the inner text
          modify_editors_notes_inner_text!(xn)
          pull_node(xn)
        when 'location' == c
          # span.Location -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'paragraph' == c
          # span.Paragraph -> span.pn
          # QUESTION: do we want the paragraph number text?
          text_el = Kramdown::ElementRt.new(:text, xn.text.gsub('E-', '').strip)
          em_el = Kramdown::ElementRt.new(:em, nil, { 'class' => 'pn' })
          em_el.add_child(text_el)
          @ke_context.get_current_text_container(xn).add_child(em_el)
          @xn_context.process_children = false
        when 'questioncomments' == c
          # span.QuestionComments -> *not* bold, even if overlapped with span.Questions
          # or another bold style. Treat like ScriptureComments.
          # TODO: implement this
        when 'questions' == c
          # span.Questions -> ** ** (bold). Set parent paragraph class to "q".
          strong_el = Kramdown::ElementRt.new(:strong)
          @ke_context.get_current_text_container(xn).add_child(strong_el)
          @ke_context.get('p', xn).add_class('q')
          @ke_context.with_text_container_stack(strong_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when 'recordheading' == c
          # span.recordHeading -> pull
          pull_node(xn)
        when %[redletterscripturereading scripturereading].include?(c)
          # span.RedLetterScriptureReading, span.ScriptureReading -> markdown italics (*text*)
          em_el = Kramdown::ElementRt.new(:em)
          @ke_context.get_current_text_container(xn).add_child(em_el)
          @ke_context.with_text_container_stack(em_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when %[scripturecomments scriptureparaphrase].include?(c)
          # span.ScriptureComments, span.ScriptureParaphrase -> *no* italics.
          # Ensure no italics are applied, even if there is an overlap with
          # span.ScriptureReading or span.RedLetterScriptureReading. Use temporary
          # placeholder class that will prevent merging of overlapping elements
          # in second phase, then remove placeholder classes.
          # TODO: implement this
        when %[singing singingcomments zzpoems].include?(c)
          # span.Singing, span.SingingComments, span.zzPoems -> pull
          pull_node(xn)
        when %[smcaps1 smcaps2 zvgrscripturesmallcaps].include?(c)
          # span.SmCaps1, span.SmCaps2, span.zVGRScriptureSmallCaps -> span.smcaps
          # (join subsequent elements, deduplicate classes).
          # TODO: do join/dedup in post processing
          span_el = Kramdown::ElementRt.new(:em, nil, 'class' => 'smcaps')
          @ke_context.get_current_text_container(xn).add_child(span_el)
          @ke_context.with_text_container_stack(span_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when 'subsuperscript' == c
          # span.subsuperscript ->  pull
          pull_node(xn)
        when 'tapeleveldatecodeletter' == c
          # span.tapeleveldatecodeletter -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'tapetitle' == c
          # span.TapeTitle -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
          # span.TapeTitle (inside record[level=tape]) -> pull
          # NOTE: this is handled in process_node_record (tape)
        when 'time' == c
          # span.Time -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'tls' == c
          # link.TLS, span.TLS -> delete any instances of the † character (U+2020),
          # then pull the element.
          replace_string_inside_node!("†", '', xn)
          pull_node(xn)
        when %[vgrspeaker zvgrspeaker].include?(c)
          # span.VGRSpeaker, span.zVGRSpeaker -> delete any instances of the
          # character « (U+00AB) character, then pull the element
          replace_string_inside_node!("«", '', xn)
          pull_node(xn)
        when 'zbold' == c
          # span.zBold type="highlighter" -> bold
          strong_el = Kramdown::ElementRt.new(:strong)
          @ke_context.get_current_text_container(xn).add_child(strong_el)
          @ke_context.with_text_container_stack(strong_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when 'zhelenindiscernible' == c
          # span.zhelenindiscernible -> pull
          pull_node(xn)
        when 'zlevelrecordlocation' == c
          # span.zlevelrecordlocation -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'zlevelrecordtapenumber' == c
          # span.zlevelrecordtapenumber -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'zlevelrecordtitle' == c
          # span.zlevelrecordtitle (inside record[level=tape]) -> h1
          # (after Camel casing from all caps). Compare this to the one we get
          # from the first note.
          # NOTE: this is implemented in process_node_record (tape)
        when 'zlevelrecordtitleauxiliary' == c
          # span.zlevelrecordtitleauxiliary -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'zlevelrecordv-n-' == c
          # span.zlevelrecordv-n- -> Delete (sending to both deleted text and editors notes)
          delete_node(xn, true, true)
        when 'zunderlinedwords-prophetindicatedsuch' == c
          # span.zUnderlinedWords-prophetindicatedsuch -> span.underline
          span_el = Kramdown::ElementRt.new(:em, nil, 'class' => 'underline')
          @ke_context.get_current_text_container(xn).add_child(span_el)
          @ke_context.with_text_container_stack(span_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when 'zvgreagle' == c
          # span.zVGREagle -> Verify contents includes one ` (backtick), replace
          # it with U+F6E1, and pull span tag.
          if xn.text != "`"
            add_warning(xn, "zVGREagle contained unexpected chars: #{ xn.text.inspect }")
          end
          replace_string_inside_node!("`", "\uF6E1", xn)
        when 'zvgrhighorderbitword' == c
          # span.zVGRHighOrderBitWord -> pull. (used to indicate words with
          # codepoints > 128, perhaps warn?)
          # QUESTION: should we warn?
          pull_node(xn)
        when 'zvgritalics' == c
          # span.zVGRItalics -> markdown italics (*text*)
          em_el = Kramdown::ElementRt.new(:em)
          @ke_context.get_current_text_container(xn).add_child(em_el)
          @ke_context.with_text_container_stack(em_el) do
            xn.children.each { |xnc| process_xml_node(xnc) }
          end
          @xn_context.process_children = false
        when 'zvgrwingdings' == c
          # span.zVGRWingdings -> Ensure only contains « « « « « « « (Ux00AB)
          # and whitespace, replace with horizontal rule.
          if xn.text !~ /\A[\s«]+\z/
            add_warning(xn, "zVGRWingdings contained unexpected chars: #{ xn.text.inspect }")
          end
          hr_el = Kramdown::ElementRt.new(:hr)
          @ke_context.get_current_text_container(xn).add_child(hr_el)
          @xn_context.process_children = false
        when 'zzzkpn' == c
          # span.zzzKPN -> Save trimmed text contents to record token
          # (IAL under 'kpn' attribute), then delete the node and any children.
          # Warn if there is more than one per record or if text contents is not just digits.
          t = xn.text.strip
          if t !~ /\A\d+\z/
            add_warning(xn, "span.zzzKPN contains non-digit text: #{ tc.inspect }")
          end
          @ke_context.set_attr_on_record_mark(xn, 'kpn', t, true)
          @xn_context.process_children = false
        when 'zzzpid' == c
          # span.zzzPID -> Verify contents match the parent record recordID field,
          # then delete. Warn if there is a mismatch. Must happen before
          # p.referenceline(cab) is deleted.
          if xn.text != @ke_context.get('record_id', xn)
            add_warning(
              xn,
              "span.zzzPID was different from parent record_id: #{ xn.text } != #{ @ke_context.get('record_id', xn) }"
            )
          end
        when c =~ /\Azz/
          # span[class=~zz] -> pull all other classes that start with 'zz'
          pull_node(xn)
        else
          return false # return early without calling flag_match_found
        end
        flag_match_found
      end

      def process_node_style_def(xn)
        ignore_node(xn)
        flag_match_found
      end

      def process_node_table(xn)
        # table, td, tr -> Pull for now, but issue warning
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      def process_node_td(xn)
        # table, td, tr -> Pull for now, but issue warning
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      def process_node_text(xn)
        @ke_context.add_text_to_current_text_container(xn.text, xn)
        flag_match_found
      end

      def process_node_tr(xn)
        # table, td, tr -> Pull for now, but issue warning
        pull_node(xn)
        add_warning(xn, "Found #{ xn.name_and_class }")
        flag_match_found
      end

      # ***********************************************************
      # xn processing helper methods
      # ***********************************************************

      # Capitalizes each word in string:
      # 'this IS a string to CAPITALIZE' => 'This Is A String To Capitalize'
      # @param[String] a_string
      def capitalize_each_word_in_string(a_string)
        a_string.split.map { |e| e.capitalize }.join(' ')
      end

      # Delete xn, send to deleted_text, children won't be processed
      # @param[Nokogiri::XML::Node] xn
      # @param[Boolean] send_to_deleted_text whether to send node's text to deleted_text
      # @param[Boolean] send_to_editors_notes whether to send node's text to editors_notes
      def delete_node(xn, send_to_deleted_text, send_to_editors_notes)
        @xn_context.process_children = false
        add_deleted_text(xn, xn.text)  if send_to_deleted_text
        add_editors_notes(xn, xn.text)  if send_to_editors_notes
      end

      # Deletes a_string from xn and all its descendant nodes.
      # @param[String, Regexp] search_string_or_regex a string or regex for finding
      # @param[String] replace_string the replacement string
      # @param[Nokogiri::XML::Node] xn
      def replace_string_inside_node!(search_string_or_regex, replace_string, xn)
        if xn.text? && '' != xn.text && !xn.text.nil?
          xn.content = xn.text.gsub(search_string_or_regex, replace_string)
        else
          xn.children.each { |child_xn|
            replace_string_inside_node!(search_string_or_regex, replace_string, child_xn)
          }
        end
      end

      # Call this from xn processing methods where we want to record that a match
      # has been found. This is used so that we can raise a warning for any
      # unhandled XML nodes.
      def flag_match_found
        @xn_context.match_found = true
      end

      # Ignore xn, don't send to deleted_text, children won't be processed
      # @param[Nokogiri::XML::Node] xn
      def ignore_node(xn)
        @xn_context.process_children = false
      end

      def modify_editors_notes_inner_text!(xn)
        if xn.text? && '' != xn.text && !xn.text.nil?
          # [Blank.spot.on.tape--Ed.] -> [Blank spot on tape—Ed.]
          # When removing periods from blank.spot.on.tape be aware that not all
          # of them end with –Ed. Some are: [blank.spot.on.tape] most are
          # [blank.spot.on.tape—Ed.]
          xn.content = xn.text.gsub(/(\[)([\w\.]+)((—Ed\.)?\])/) { |s|
            _full_match, br1, txt, br2 = *Regexp.last_match
            br1 + txt.gsub(/\./, ' ') + br2
          }
        else
          xn.children.each { |child_xn|
            modify_editors_notes_inner_text!(child_xn)
          }
        end
      end

      # Pull xn, Replacing self with children. Xml tree recursion will process children.
      # @param[Nokogiri::XML::Node] xn
      def pull_node(xn)
        # nothing to do with node
      end

      # Update record ids every time we encounter a record-node.
      # @param[Nokogiri::XML::Node] xn
      def update_record_ids_in_ke_context(xn)
        year_id, tape_id, record_id = xn['fullPath'].gsub(/\A\//, '').split('/').map(&:strip)
        @ke_context.set('year_id', year_id)
        @ke_context.set('tape_id', tape_id)
        @ke_context.set('record_id', record_id)
      end

      # Raises a warning and returns false if xn contains any text content other
      # than whitespace.
      # @param[Nokogiri::XML::Node] xn
      def verify_only_whitespace_is_present(xn)
        t = xn.text.strip
        if(t =~ /\A[ \n]*\z/)
          true
        else
          add_warning(
            xn,
            "#{ xn_name_and_class(xn) } contained non-whitespace: #{ t.inspect }"
          )
          false
        end
      end

      # Returns name and class of xn in CSS notation
      # @param[Nokogiri::XML::Element] el
      def xn_name_and_class(xn)
        [xn.name, xn['class']].compact.join('.')
      end

      def xn_name_and_class_path(xn, downstream_path = '')
        downstream_path = xn_name_and_class(xn) + downstream_path
        if xn.parent && !xn.parent.xml?
          # Recurse to parent unless it's the top level XML Document node (.xml?)
          xn_name_and_class_path(xn.parent, ' > ' + downstream_path)
        else
          # This is the top level node
          return downstream_path
        end
      end

    end
  end
end
