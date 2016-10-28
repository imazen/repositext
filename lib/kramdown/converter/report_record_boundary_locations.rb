# Returns a summary of record boundary locations. This is useful to run on
# foreign language repos where record boundaries are tied to subtitle_marks.

module Kramdown
  module Converter

    # Returns summary of where record boundaries are located:
    # * summary of all record boundaries
    #     * what does it fall inside of:
    #         * root
    #         * paragraph
    #         * span
    #     * count
    class ReportRecordBoundaryLocations < Base

      # Instantiate converter
      # @param root [Kramdown::Element]
      # @param options [Hash{Symbol => Object}]
      #     Expects key :subtitles with Array<Repositext::Subtitle> for all
      #     subtitles in the current document.
      def initialize(root, options)
        super
        @subtitles = options[:subtitles]
        # this is where we track what we're inside of, and the child index of
        # the current element (1 based).
        # It could be for example
        # [{ type: :root, current_child_index: 1}, { type: :paragraph, current_child_index: 0}]
        @containment_stack = []
        @report = { root: 0, paragraph: 0, span: 0, comments: [] }
        @current_record_id = nil
      end

      # @param [Kramdown::Element] el
      def convert(el)
        containment = nil
        case el.type
        when :root
          containment = { type: :root, current_child_index: 0 }
        when :header, :hr, :p
          containment = { type: :paragraph, current_child_index: 0 }
        when :em, :strong
          containment = { type: :span, current_child_index: 0 }
        when :subtitle_mark
          subtitle = @subtitles.shift
          is_record_boundary = (subtitle.record_id != @current_record_id)
          is_first_child = (1 == @containment_stack.last[:current_child_index])
          if is_record_boundary
            @current_record_id = subtitle.record_id
            if is_first_child
              # record on grandparent containment
              containment_type = @containment_stack[-2][:type]
            else
              # record on parent containment
              containment_type = @containment_stack.last[:type]
            end
            if :span == containment_type
              @report[:comments] << "STM inside span: #{ @containment_stack.inspect }"
            end
            @report[containment_type] += 1
          end
        when :record_mark
          # NOTE: This report is intended for foreign files, so we ignore
          # the first record mark in each file.
        when :blank, :text
          # Nothing to do
        else
          raise "Handle this: #{ el.type.inspect }"
        end
        if containment
          # Push containment onto stack
          @containment_stack.push(containment)
            # walk the tree, update child index
            el.children.each { |e|
              @containment_stack.last[:current_child_index] += 1
              convert(e)
            }
          @containment_stack.pop
        else
          # Work with existing containment stack
          # walk the tree, update child index
          el.children.each { |e|
            @containment_stack.last[:current_child_index] += 1
            convert(e)
          }
        end

        if :root == el.type
          # Report mismatch in subtitles between subtitle_marks in content and
          # those in STM CSV file.
          raise "Remaining subtitles: #{ @subtitles.count }"  if !@subtitles.empty?
          return @report
        end
      end

    end
  end
end
