# -*- coding: utf-8 -*-

module Kramdown
  module Converter

    # Converts tree to subtitle text
    class Subtitle < Base

      # Instantiate a Subtitle converter
      # @param [Kramdown::Element] root
      # @param [Hash] options
      def initialize(root, options)
        super
        @output = '' # collector for output string
      end

      # Extracts subtitle from tree
      # @param [Kramdown::Element] el
      # @return [String] the subtitle text
      def convert(el)
        case el.type
        when :blank
          # nothing to do
        when :em
          if el.has_class?('pn')
            # replace space after paragraph numbers with 4 spaces. Done in post processing
            @output << "<<replace space after with 4 spaces>>"
          end
        when :entity
          # Decode whitelisted entities
          @output << Repositext::Utils::EntityEncoder.decode(el.options[:original])
        when :gap_mark
          # export gap_marks
          @output << gap_mark_output
        when :header
          # put opening part of header wrapper. Post processing will close it
          case el.options[:level]
          when 1
            # render as H1
            @output << "\n[|# "
          when 2
            # render as H2
            @output << "\n[|## "
          when 3
            # render as H3
            @output << "\n\n[|### "
          else
            raise "Unhandled header type: #{ el.inspect }"
          end
        when :p
          if %w[id_title1 id_title2 id_paragraph].any? { |e| el.has_class?(e) }
            # mark for deletion in post processing
            @output << "\n\n<<delete this line>>"
          else
            # put empty lines between paras
            @output << "\n\n"
          end
        when :hr
          # nothing to do
        when :record_mark
          # nothing to do
        when :root
          # nothing to do
        when :strong
          # nothing to do
        when :subtitle_mark
          # export gap_marks
          @output << subtitle_mark_output
        when :text
          # capture value of all :text elements
          @output << el.value
        else
          raise "Handle this element: #{ el.inspect }"
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

      def subtitle_mark_output
        # subtitle_marks are rendered for subtitle output
        '@'
      end

      def post_process_output(raw_output)
        r = raw_output.dup
        # delete lines that are marked for deletion
        r.gsub!(/\n\n<<delete this line>>[^\n]*/, '')
        # replace space after paragraph number with 4 spaces
        r.gsub!(/<<replace space after with 4 spaces>>([^\s]*)\s*/, '\1    ')
        # close wrap title in brackets and pipes
        r.gsub!(/(?<=\[\|#)([^\n]*)/, '\1|]')
        # move subtitle marks that are inside header wrappers to before the wrapper
        r.gsub!(/(?<=\n)(\[\|[#]+\s+)(@)/, '\2\1')
        # trim leading and trailing whitespace
        r.strip!
        r << "\n" # add single newline to end of file to comply with repositext file conventions
        r = add_subtitle_mark_to_beginning_of_first_paragraph(r)
        r
      end

      # Adds a '@' to the beginning of the first paragraph if txt doesn't contain
      # any subtitle_marks yet. This is so that the software that uses this file
      # detects it as a subtitle file
      # @param [String] txt
      # @return [String]
      def add_subtitle_mark_to_beginning_of_first_paragraph(txt)
        return(txt)  if txt.index('@')
        # Insert '@' in the first line that contains text and is not a header
        txt.sub(/(\n)(?!(\s|\[\|\#))/, '\1@')
      end

    end
  end
end
