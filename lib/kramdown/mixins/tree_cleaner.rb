# Include this module into any library that wants to clean up a kramdown tree

# NOTE: This requires the tree traversal and manipulation methods defined in
# Kramdown::ElementRt

module Kramdown
  module TreeCleaner

    # Recursively cleans up tree under ke
    # @param[Kramdown::Element] ke
    def recursively_clean_up_tree!(ke)
      # Work from the bottom up so that tree mutations don't interfere with
      # iteration of children.
      # First iterate over children
      ke.children.each { |cke| recursively_clean_up_tree!(cke) }
      # Then do mutation on current ke at the end
      clean_up_tree_element!(ke)
    end

    # Cleans up ke
    # @param[Kramdown::Element] ke
    def clean_up_tree_element!(ke)
      if :hr == ke.type
        ke.children.clear
      elsif [:em, :strong].include?(ke.type) && ke.children.none?
        # span element is empty and can be completely deleted
        ke.detach_from_parent
      elsif(
        :p == ke.type &&
        (ke.children.none? || ke.children.all? { |ke_c|
          :text == ke_c.type && ['', nil].include?(ke_c.value.to_s.strip)
        })
      )
        # para is empty or contains whitespace only and can be completely deleted
        ke.detach_from_parent
      elsif :text == ke.type && ['', nil].include?(ke.value)
        # remove node
        ke.detach_from_parent
      end
    end

  end
end
