# Include this module into any library that wants to merge adjacent kramdown
# elements if they are of the same type.

module Kramdown
  module AdjacentElementMerger

    # Recursively merges adjacent elements of same type.
    # @param[Kramdown::Element] ke
    def recursively_merge_adjacent_elements!(ke)
      # Work from the bottom up so that tree mutations don't interfere with
      # iteration of children.
      # First iterate over children
      ke.children.each { |cke| recursively_merge_adjacent_elements!(cke) }
      # Then do mutation on current ke at the end
      merge_adjacent_child_elements!(ke)
    end

    # Merges any children of ke that are adjacent and of the same type and have
    # same salient attributes.
    # NOTE: this doesn't do any recursion. It operates on a single ke only.
    # @param[Kramdown::Element] ke
    # @return[Integer] index of the last processed element
    def merge_adjacent_child_elements!(ke)
      if ke.children.first.nil? || :span != ::Kramdown::Element.category(ke.children.first)
        # No merging is possible, early exit
        return nil
      end
      index = 0
      while index < ke.children.length - 1 # only need to go to second to last child
        cur_ke = ke.children[index]
        next_ke = ke.children[index + 1]
        next_next_ke = ke.children[index + 2]
        if(
          cur_ke.type == next_ke.type &&
          cur_ke.attr == next_ke.attr &&
          cur_ke.options.select {|k,v| :location != k } == next_ke.options.select {|k,v| :location != k }
        )
          if cur_ke.type == :text
            cur_ke.value += next_ke.value
          else
            cur_ke.children.concat(next_ke.children)
          end
          ke.children.delete_at(index + 1)
        elsif(
          next_next_ke && [:em, :strong].include?(next_next_ke.type) &&
          next_ke.type == :text && next_ke.value.strip.empty? &&
          next_next_ke.type == cur_ke.type && next_next_ke.attr == cur_ke.attr &&
          cur_ke.options.select {|k,v| :location != k } == next_ke.options.select {|k,v| :location != k }
        )
          cur_ke.children.push(next_ke)
          cur_ke.children.concat(next_next_ke.children)
          # Important: delete_at index+2 first, so that the other element is still
          # at index+1. If we delete index+1 first, then the other element
          # we want to delete is not at index+2 any more, but has moved up to index+1
          ke.children.delete_at(index + 2)
          ke.children.delete_at(index + 1)
        else
          index += 1
        end
      end

    end

  end
end
