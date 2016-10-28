module Kramdown
  # Include this module into any library that wants to process :em elements with
  # tmp classes for the purpose of breaking out of an italic or bold span.
  module TmpEmClassProcessor

    # Walks the ke tree, finds any tmp classes that were added to
    # remove bold or italic from a span.
    # @param [Kramdown::Element] ke the root node of a kramdown tree
    # @param [String] tmp_class_name the name of the tmp class
    def recursively_process_temp_em_class!(ke, tmp_class_name)
      # First iterate over children, use queue to decouple it from a parent's children
      # collection. This is important to make recursion work.
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        recursively_process_temp_em_class!(ke_child, tmp_class_name)
      end
      # Then process ke
      if [:em, :strong].include?(ke.type)
        # Inside em, with possibility of nested tmp_classes
        process_nested_temp_em_class!(ke, tmp_class_name)
      else
        # Simple case with no possibility of nested tmp_classes
        process_non_nested_temp_em_class!(ke, tmp_class_name)
      end
    end

    # Processes any children of ke that have tmp_class_name. This handles
    # the simple case where element with tmp_class_name is not nested inside
    # another :em.
    # @param [Kramdown::Element] ke the root node of a kramdown tree
    # @param [String] tmp_class_name the name of the tmp class
    def process_non_nested_temp_em_class!(ke, tmp_class_name)
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        if(:em == ke_child.type && ke_child.has_class?(tmp_class_name))
          # replace ke_child with its children
          ke_child.replace_with(ke_child.children)
        end
      end
    end


    # Processes any children of ke that have tmp_class_name. This handles
    # the more complex case where element with tmp_class_name is nested inside
    # another :em.
    # @param [Kramdown::Element] ke the root node of a kramdown tree
    # @param [String] tmp_class_name the name of the tmp class
    def process_nested_temp_em_class!(ke, tmp_class_name)
      ke_child_processing_queue = ke.children.dup # duplicate list with references to same objects
      ke_sibling_processing_queue = [] # for any new ke siblings we create
      cur_ke_level_el = ke # pointer to the current element at ke-level
      ke_s_to_delete = [] # list of elements that may have to be deleted
      while(ke_child = ke_child_processing_queue.shift) do
        if(:em == ke_child.type && ke_child.has_class?(tmp_class_name))
          # Found tmp (ke_child)
          if ke_child.children.any?
            if ke_child == cur_ke_level_el.children.first
              # cur_ke_level_el has no children before ke_child, so we can delete it
              ke_s_to_delete << cur_ke_level_el
            end
            tmp_ke_level_el = ke_child.children.last # record so that we can add cur_ke_level_el as sibling after
            cur_ke_level_el.insert_sibling_after(ke_child.children) # Move tmp's children as siblings after cur_ke_level_el
            cur_ke_level_el = cur_ke_level_el.clone(false) # create new ke-level parent, move as sibling after tmp_ke_level_el
            tmp_ke_level_el.insert_sibling_after(cur_ke_level_el)
            ke_s_to_delete << cur_ke_level_el # mark for deletion (if no children are added)
          end
          ke_child.detach_from_parent
        elsif(cur_ke_level_el != ke)
          # Found sibling after tmp
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
      ke_sibling_processing_queue.each { |e| recursively_process_temp_em_class!(e, tmp_class_name) }
      # Delete all elements marked for deletion
      ke_s_to_delete.each { |e| e.detach_from_parent }
    end

  end
end
