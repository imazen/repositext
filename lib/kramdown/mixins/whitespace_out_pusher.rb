# Include this module into any library that wants to push out whitespace from
# :em and :strong

# NOTE: This requires the tree traversal and manipulation methods defined in
# Kramdown::ElementRt

module Kramdown
  module WhitespaceOutPusher

    # Recursively pushes out whitespace from :em and :strong elements
    # @param[Kramdown::Element] ke
    def recursively_push_out_whitespace!(ke)
      # Work from the bottom up so that tree mutations don't interfere with
      # iteration of children.
      # First iterate over children, use queue to decouple it from a parent's children
      # collection. This is important to make recursion work.
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        recursively_push_out_whitespace!(ke_child)
      end
      # Then do mutation on current ke at the end
      push_out_whitespace!(ke)
    end

    # Pushes out whitespace from :em and :strong elements
    # @param[Kramdown::Element] ke
    def push_out_whitespace!(ke)
      if [:em, :strong].include?(ke.type) && ke.children.any?
        if :text == ke.children.first.type && ke.children.first.value =~ /\A[ \n\t]+/
          # push out leading whitespace
          ke.children.first.value.lstrip!
          if(prev_sib = ke.previous_sibling).nil? || (:text != prev_sib.type)
            # previous sibling doesn't exist or is something other than :text
            # Insert a :text el as previous sibling
            ke.insert_sibling_before(Kramdown::ElementRt.new(:text, ' '))
          else
            # previous sibling is :text el
            # Append leading whitespace
            prev_sib.value << ' '
          end
        end
        if :text == ke.children.last.type && ke.children.last.value =~ /[ \n\t]+\z/
          # push out trailing whitespace
          ke.children.last.value.rstrip!
          if(foll_sib = ke.following_sibling).nil? || (:text != foll_sib.type)
            # following sibling doesn't exist or is something other than :text
            # Insert a :text el as followings sibling
            ke.insert_sibling_after(Kramdown::ElementRt.new(:text, ' '))
          else
            # following sibling is :text el
            # Prepend trailing whitespace
            foll_sib.value = ' ' + foll_sib.value
          end
        end
      end
    end

  end
end
