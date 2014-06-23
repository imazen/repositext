# Returns a list of paragraph class combinations
module Kramdown
  module Converter
    class ReportParagraphClassesInventory < Base

      # Instantiate converter
      # @param[Kramdown::Element] root
      # @param[Hash] options
      def initialize(root, options)
        super
        @paragraph_classes_inventory
      end

      # @param[Kramdown::Element] el
      # @return[Hash] all paragraph combinations and their isntance count as Hash:
      #   {
      #     ['class1', 'class2'] => 4, # keys are combinations of paragraph classes, values are instance counts
      #     ['class3'] => 2, # keys are combinations of paragraph classes, values are instance counts
      #   }
      def convert(el)
        if :p == el.type
          @paragraph_classes_inventory
        end
        # walk the tree
        el.children.each { |e| convert(e) }
        if :root == el.type
          return @paragraph_classes_inventory
        end
      end

    end
  end
end
