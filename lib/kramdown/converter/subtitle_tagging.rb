# -*- coding: utf-8 -*-

# Converts tree to subtitle tagging
module Kramdown
  module Converter
    class SubtitleTagging < Base

      # Instantiate a SubtitleTagging converter
      # @param[Kramdown::Element] root
      # @param[Hash] options
      def initialize(root, options)
        super
        @output = '' # collector for output string
      end

      # Extracts subtitle tagging from tree
      # @param[Kramdown::Element] el
      # @return[String] the subtitle tagging text
      def convert(el)
        case
        when :header == el.type
          # put opening part of header wrapper. Post processing will close it
          @output << "\n[|# "
        when :p == el.type
          if %w[id_title1 id_title2 id_paragraph].any? { |e| el.has_class?(e) }
            # mark for deletion in post processing
            @output << "\n\n<<delete this line>>"
          else
            # put empty lines between paras
            @output << "\n\n"
          end
        when :gap_mark == el.type
          # export gap_marks
          @output << "%"
        when :em == el.type && el.has_class?('pn')
          # replace space after paragraph numbers with 4 spaces. Done in post processing
          @output << "<<replace space after with 4 spaces>>"
        when :text == el.type
          # capture value of all :text elements
          @output << el.value
        end
        # walk the tree
        el.children.each { |e| convert(e) }
        if :root == el.type
          # return @output for :root element
          return post_process_output(@output)
        end
      end

    protected

      def post_process_output(raw_output)
        r = raw_output.dup
        r.gsub!(/\n\n<<delete this line>>[^\n]*/, '') # delete lines that are marked for deletion
        r.gsub!(/<<replace space after with 4 spaces>>([^\s]*)\s*/, '\1    ') # replace space after paragraph number with 4 spaces
        r.gsub!(/(?<=\n\[\|\# )([^\n]*)/, '\1|]') # close wrap title in brackets and pipes
        r.gsub!(/ ? ?/, '') # remove beginning and ending eagles
        r.strip!
        r << "\n\n" # add two newlines to end of file to comply with repositext file conventions
        r
      end

    end
  end
end

=begin

# Text Repository Export Requirements for Subtitling with MacCaption

* file name is [datecode].rt.txt but I prefer [datecode].[two letter country code].rt.txt
* wrap title in with brackets and pipe ex: [|# The Greatest Battle Ever Fought|]
* red gap marks must be in the text
* remove paragraph number span classes and convert the space that follows it to 4 spaces
* ~~insert "\n[|song|]" and "\n[|stanza|]" at the beginning of the the song and stanza paragraph~~
* remove the contents and classes for id_title1, id_title2, id_paragraph
* remove beginning and ending VGR eagles
* except for the above, other wise the same as plain text
  * remove all span and paragraph classes
  * remove all bold, italics and underline, small caps, and any other special classes
  * remove all recordIds and new line in it
  * unescape all any escaped characters [, ], :
  * remove any horizontal rules
* the paragraphs need to have no formatting on the paragraphs (no word wrapping)

# Questions about TR

* Can paragraphs in the TR start with '@' before the paragraph number?
  Answer (JH): Yes, it's fine to start a line with an '@' character before the para number.
* Aaron to clarify how we can guarantee that subtitle spans don't cross
  record_id boundaries if we remove record_ids in cmi exported files?
  Answer (AW): The text splitting script will place a @ subtitle_mark at the beginning of every paragraph.

* Somewhat off topic, but for the import into the TR the gap marks will not be added in unless they are needed. Will this work?

**Notes: Removed requirement for keeping the songs and stanza classes in the export.**



#Import from mac caption:

same as what we export with the following differences:

* no gap marks (%)
* with subtitle marks (@)

There should be no text changes, so we shouldn't use TextReplayer to confirm
that no text was changed on either side since the export.

Import merges the new subtitle marks into content AT using suspensions.

There should currently be no subtitle marks in content.

=end
