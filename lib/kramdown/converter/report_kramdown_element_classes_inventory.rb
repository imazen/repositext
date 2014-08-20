# Returns a list of kramdown element class combinations
module Kramdown
  module Converter
    class ReportKramdownElementClassesInventory < Base

      # Instantiate converter
      # @param[Kramdown::Element] root
      # @param[Hash] options
      def initialize(root, options)
        super
        @classes_inventory = {}
      end

      # @param[Kramdown::Element] el
      # @return[Hash] all element types, class combinations and their instance count as Hash:
      #   {
      #     'p' => {
      #       ['class1', 'class2'] => 4, # keys are combinations of paragraph classes, values are instance counts
      #       ['class3'] => 2, # keys are combinations of paragraph classes, values are instance counts
      #     },
      #     'em' => ...
      #   }
      def convert(el)
        el_type_key = el.type.to_s
        @classes_inventory[el_type_key] ||= Hash.new(0)
        @classes_inventory[el_type_key][el.get_classes] += 1
        # walk the tree
        el.children.each { |e| convert(e) }
        if :root == el.type
          return @classes_inventory
        end
      end

    end
  end
end
