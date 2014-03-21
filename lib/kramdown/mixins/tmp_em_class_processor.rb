# Include this module into any library that wants to process :em elements with
# tmp classes for the purpose of breaking out of an italic or bold span.

module Kramdown
  module TmpEmClassProcessor

    # Walks the ke tree, finds any tmp classes that were added to
    # remove bold or italic from a span.
    # @param[Kramdown::Element] ke the root node of a kramdown tree
    # @param[String] tmp_class_name the name of the tmp class
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
    # @param[Kramdown::Element] ke the root node of a kramdown tree
    # @param[String] tmp_class_name the name of the tmp class
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
    # @param[Kramdown::Element] ke the root node of a kramdown tree
    # @param[String] tmp_class_name the name of the tmp class
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

    # Walks the ke tree, finds any tmp classes that were added to
    # remove bold or italic from a span.
    #
    # Algorithm overview:
    # * copy ke's children into processing_queue
    # * while child_ke = processing_queue.shift
    #   * if child_ke is em.tmp_class_name
    #     * process child_ke
    #   * elsif found_child_with_tmp_class_name
    #     * process child_ke's following siblings
    #       * create new_parent_for_following_siblings as sibling to ke
    #       * add child_ke as child to new_parent_for_following_siblings
    #   * else
    #     * nothing to do for previous siblings
    #   * recurse over child_ke
    # * recurse over new_parent_for_following_siblings if it exists
    # @param[Kramdown::Element] ke the root node of a kramdown tree
    # @param[String] tmp_class_name the name of the tmp class
    def process_temp_em_class_x(ke, tmp_class_name)
      # TODO: how do we walk the tree?
      # * pre-order (current node, then its children)
      # * post-order (children, then current node)
      # * level-order (all sibling nodes, then their children)
      # The best approach for this method is
      # Have to manage processing queue independently from ke tree since
      # we mutate the tree (add and remove elements), which throws off
      # the iterator. For isolation at the tree level, I copy references to
      # each element in `children` (via dup), rather than assigning a reference
      # to the entire `children` collection.
      ke_child_processing_queue = ke.children.dup
      found_child_with_tmp_class_name = false
      new_parent_for_following_siblings = nil
      while(ke_child = ke_child_processing_queue.shift) do
        if ke_child.has_class?(tmp_class_name) && !found_child_with_tmp_class_name
          if [:em, :strong].include?(ke.type)
            # Found first child with tmp_class_name
            found_child_with_tmp_class_name = true
            # ke_child is nested inside :em or :strong, do the magic
            if ke_child.is_only_child?
              # Scenario 1:
              #  CONVERT THIS                          INTO    THIS
              #  - :em [ke]                                     -> (deleted)
              #    - :em - {"class"=>"tmpNoItalics"} [ke_child] -> (deleted)
              #      - :text - "He called me"                   -> - :text - "He called me"
              # * replace ke with ke_child's children
              ke.replace_with(ke_child.children)
            else
              # Scenario 2:
              #  CONVERT THIS                          INTO    THIS
              #  - :em [ke]                                     -> - :em
              #    - :text - "This day "                        ->   - :text - "This day "
              #    - :em - {"class"=>"tmpNoItalics"} [ke_child] ->   (deleted)
              #      - :text - "has"                            -> - :text - "has"
              #                                                 -> - :em
              #    - :text - " this "                           ->   - :text - " this "
              #    - :em - {"class"=>"tmpNoItalics"}            ->   - :em - {"class"=>"tmpNoItalics"}
              #      - :text - "word been"                      ->     - :text - "word been"
              # * leave ke_child's previous siblings alone
              # * remove ke_child, make ke_child's children following siblings of ke
              # * make ke_child's following siblings children of new_parent_for_following_siblings
              #   (which is a following sibling of ke)
              ke_child.detach_from_parent
              ke.insert_sibling_after(ke_child.children)
            end
          else
            # ke_child is not nested inside :em or :strong,
            # Pull the tmp :em and replace with children
            ke_child.replace_with(ke_child.children)
          end
        elsif found_child_with_tmp_class_name
          # Following siblings, add as children to new_parent_for_following_siblings
          if new_parent_for_following_siblings.nil?
            # create new detached element (no parent, no children)
            new_parent_for_following_siblings = ke.clone(false)
            # Add new_parent_for_following_siblings as last sibling to ke
            # TODO: figure out if it should be next or last sibling.
            ke.insert_sibling_after(new_parent_for_following_siblings)
            #ke.parent.add_child(new_parent_for_following_siblings)
          end
          # re-parent ke_child to new_parent_for_following_siblings
          # merge ke_child with new_parent_for_following_siblings if same
          new_parent_for_following_siblings.add_child_or_reuse_if_same(ke_child)
        else
          # We haven't reached ke_child with tmp_class_name yet, nothing to do
        end
        # Recurse over entire tree
        process_temp_em_class(ke_child, tmp_class_name)
      end
      # Process new_parent_for_following_siblings if it exists
      if new_parent_for_following_siblings
        process_temp_em_class(new_parent_for_following_siblings, tmp_class_name)
      end
    end
  end
end
