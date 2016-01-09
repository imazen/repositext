# Returns a list of question paragraphs that are not perfectly aligned with the
# contained span.
module Kramdown
  module Converter
    class ReportMisalignedQuestionParagraphs < Base

      # Instantiate converter
      # @param [Kramdown::Element] root
      # @param [Hash] options
      def initialize(root, options)
        super
        @misaligned_question_paragraphs = []
      end

      # @param [Kramdown::Element] el
      # @return [Array] all misaligned question paras:
      #   [
      #     { location: , source: '' },
      #   ]
      def convert(el)
        if :p == el.type && el.has_class?('q')
          if el.children.any? { |c_el| :strong != c_el.type }
            @misaligned_question_paragraphs << { source: el.inspect_tree }
          end
        end
        # walk the tree
        el.children.each { |e| convert(e) }
        if :root == el.type
          return @misaligned_question_paragraphs
        end
      end

    end
  end
end
