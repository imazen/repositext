# Include this module into any library that wants to clean up a kramdown tree

# NOTE: This requires the tree traversal and manipulation methods defined in
# Kramdown::ElementRt

module Kramdown
  module TreeCleaner

    # Recursively cleans up tree under ke
    # @param [Kramdown::Element] ke
    def recursively_clean_up_tree!(ke)
      # Work from the bottom up so that tree mutations don't interfere with
      # iteration of children.
      # First iterate over children, use queue to decouple it from a parent's children
      # collection. This is important to make recursion work.
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        recursively_clean_up_tree!(ke_child)
      end
      # Then do mutation on current ke at the end
      clean_up_tree_element!(ke)
    end

    # Cleans up ke
    # @param [Kramdown::Element] ke
    def clean_up_tree_element!(ke)
      if :hr == ke.type
        ke.children.clear
        # :hr is a block level el that shouldn't be nested inside a :p, so
        # we insert it as sibling before its parent :p. This same method will
        # then remove the empty :p if :hr was the only child.
        ke.parent.insert_sibling_before(ke)  if :p == ke.parent.type
      elsif [:em, :strong].include?(ke.type) && ke.children.none?
        # span element is empty and can be completely deleted
        ke.detach_from_parent
      elsif(
        :p == ke.type &&
        (ke.children.none? || ke.children.all? { |ke_c|
          :text == ke_c.type && '' == ke_c.value.to_s.strip
        })
      )
        # para is empty or contains whitespace only and can be completely deleted
        ke.detach_from_parent
      elsif :text == ke.type && ['', nil].include?(ke.value) # NOTE: don't strip. We want to preserve whitespace.
        # remove node
        ke.detach_from_parent
      end
    end

  end
end
