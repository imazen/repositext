# Include this module into any library that wants to process :em elements that
# are nested inside other :em elements.

module Kramdown
  module NestedEmsProcessor

    # Walks the ke tree, finds any ems nested inside other ems and processes them.
    # @param [Kramdown::Element] ke the root node of a kramdown tree
    def recursively_clean_up_nested_ems!(ke)
      # First iterate over children, use queue to decouple it from a parent's children
      # collection. This is important to make recursion work.
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        recursively_clean_up_nested_ems!(ke_child)
      end
      # Then process ke if it is an :em
      if :em == ke.type
        # Inside em, with possibility of nested ems
        clean_up_nested_ems!(ke)
      end
    end

    # Processes any children of ke (an em) that are also ems.
    # @param [Kramdown::Element] ke the root node of a kramdown tree
    def clean_up_nested_ems!(ke)
      ke_child_processing_queue = ke.children.dup # duplicate list with references to same objects
      ke_sibling_processing_queue = [] # for any new ke siblings we create
      cur_ke_level_el = ke # pointer to the current element at ke-level
      ke_s_to_delete = [] # list of elements that may have to be deleted
      while(ke_child = ke_child_processing_queue.shift) do
        if(:em == ke_child.type)
          # Found nested em (ke_child)
          if ke_child.children.any?
            if ke_child == cur_ke_level_el.children.first
              # cur_ke_level_el has no children before ke_child, so we can delete it
              ke_s_to_delete << cur_ke_level_el
            end
            ke_child.add_class('italic') # add italic class to ke_child
            cur_ke_level_el.insert_sibling_after(ke_child) # promote ke_child as sibling after cur_ke_level_el
            cur_ke_level_el = cur_ke_level_el.clone(false) # create new ke-level parent, move as sibling after ke_child
            ke_child.insert_sibling_after(cur_ke_level_el)
            ke_s_to_delete << cur_ke_level_el # mark for deletion (if no children are added)
          else
            # has no children, just remove it
            ke_child.detach_from_parent
          end
        elsif(cur_ke_level_el != ke)
          # Found sibling after nested em
          # Re-parent ke_child to cur_ke_level_el and merge ke_child with cur_ke_level_el if same
          cur_ke_level_el.add_child_or_reuse_if_same(ke_child)

          # Now that we have a child for new cur_ke_level_el, it's for real:
          ke_s_to_delete.delete(cur_ke_level_el) # Remove cur_ke_level_el from deletion list
          if !ke_sibling_processing_queue.include?(cur_ke_level_el)
            ke_sibling_processing_queue.push(cur_ke_level_el) # Put on processing queue for recursion
          end
        else
          # No tmp found yet, nothing to do
        end
      end
      # Process any new siblings we added to ke
      ke_sibling_processing_queue.each { |e| recursively_clean_up_nested_ems!(e) }
      # Delete all elements marked for deletion
      ke_s_to_delete.each { |e| e.detach_from_parent }
    end

  end
end
