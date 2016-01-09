# Include this module into any library that imports DOCX

# NOTE: This requires the tree traversal and manipulation methods defined in
# Kramdown::ElementRt

module Kramdown
  module DocxImportPostProcessor

    # Recursively post processes tree under ke
    # @param [Kramdown::Element] ke
    def recursively_post_process_tree!(ke)
      # Work from the bottom up so that tree mutations don't interfere with
      # iteration of children.
      # First iterate over children, use queue to decouple it from a parent's children
      # collection. This is important to make recursion work.
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        recursively_post_process_tree!(ke_child)
      end
      # Then do mutation on current ke at the end
      post_process_tree_element!(ke)
    end

    # Cleans up ke
    # @param [Kramdown::Element] ke
    def post_process_tree_element!(ke)
      if :text == ke.type
        # Fix elipses (from vietnamese)
        # TODO: See if we can get vietnamese translators to use proper elipses?
        ke.value.gsub!('. . .', Repositext::ELIPSIS)
      end
    end

  end
end

