# Include this module into any library that wants to merge adjacent kramdown
# elements if they are of the same type.

module Kramdown
  module AdjacentElementMerger

    # Recursively merges adjacent elements of same type.
    # @param[Kramdown::Element] ke
    def recursively_merge_adjacent_elements!(ke)
      # Work from the bottom up so that tree mutations don't interfere with
      # iteration over children.
      # First iterate over children, use queue to decouple it from a parent's children
      # collection. This is important to make recursion work.
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        recursively_merge_adjacent_elements!(ke_child)
      end
      # Then do mutation on current ke at the end
      merge_adjacent_child_elements!(ke)
    end

    # Merges any children of ke that are adjacent and of the same type and have
    # same salient attributes.
    # NOTE: this doesn't do any recursion. It operates on a single ke only.
    # @param[Kramdown::Element] ke
    # @return[Integer] index of the last processed element
    def merge_adjacent_child_elements!(ke)
      if(
        ke.children.empty? || # nothing to merge
        :block == ::Kramdown::Element.category(ke.children.first) || # can't merge paras or headers
        :entity == ke.type || # can't merge entities. They are atomic.
        :root == ke.type
      )
        return nil
      end
      index = 0
      merge_children_again = false # if we merge elements, we have to process them again
      while index < ke.children.length - 1 # only need to go to second to last child
        cur_ke = ke.children[index]
        next_ke = ke.children[index + 1]
        next_next_ke = ke.children[index + 2]
        if cur_ke.is_of_same_type_as?(next_ke)
          # We found two siblings that can be merged
          if cur_ke.type == :text
            # For text elements we concatenate value
            cur_ke.value += next_ke.value
          else
            # For other element types we append them as children to parent
            cur_ke.children.concat(next_ke.children)
            merge_children_again = true
          end
          ke.children.delete_at(index + 1) # delete the later sibling
          # don't increment index since we deleted element at index+1 position
        elsif(
          next_next_ke && [:em, :strong].include?(next_next_ke.type) &&
          next_ke.type == :text &&
          next_ke.value.strip.empty? &&
          cur_ke.is_of_same_type_as?(next_next_ke)
        )
          # We found two :em or :strong siblings that are separated by space and can be merged
          cur_ke.children.push(next_ke)
          cur_ke.children.concat(next_next_ke.children)
          # Important: delete_at index+2 first, so that the other element is still
          # at index+1. If we delete index+1 first, then the other element
          # we want to delete is not at index+2 any more, but has moved up to index+1
          ke.children.delete_at(index + 2)
          ke.children.delete_at(index + 1)
          # don't increment index since we deleted elements at index+1 and index+2 positions
          merge_children_again = true
        else
          index += 1
        end
        if merge_children_again
          # We merged ke's children. This may provide an opportunity for additional merging
          recursively_merge_adjacent_elements!(ke)
        end
      end

    end

  end
end
