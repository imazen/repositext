# -*- coding: utf-8 -*-

# Converts tree to subtitle text
module Kramdown
  module Converter
    class Subtitle < Base

      # Instantiate a Subtitle converter
      # @param[Kramdown::Element] root
      # @param[Hash] options
      def initialize(root, options)
        super
        @output = '' # collector for output string
      end

      # Extracts subtitle from tree
      # @param[Kramdown::Element] el
      # @return[String] the subtitle text
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
          @output << gap_mark_output
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

      def gap_mark_output
        # gap_marks are removed for subtitle output
        ''
      end

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
