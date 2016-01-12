# Include this module into any library that wants to push out whitespace from
# :em and :strong

# NOTE: This requires the tree traversal and manipulation methods defined in
# Kramdown::ElementRt

# TODO: if we were to adopt the code used in idml_story parser which operates
# on ke's parent, then we could get away without the tree traversal methods
# used here. And then we could unify the code used for pushing out whitespace
# in folio and idml parsers.

module Kramdown
  module WhitespaceOutPusher

    # Recursively pushes out whitespace from :em and :strong elements
    # @param [Kramdown::Element] ke
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
    # @param [Kramdown::Element] ke
    def push_out_whitespace!(ke)
      if [:em, :strong].include?(ke.type) && ke.children.any?
        fc = ke.children.first
        if :text == fc.type && fc.value =~ /\A[ \n\t]+/
          # push out leading whitespace
          fc.value.lstrip!
          if(prev_sib = ke.previous_sibling) && (:text == prev_sib.type)
            # previous sibling is :text el
            # Append whitespace
            prev_sib.value << ' '
          else
            # previous sibling doesn't exist or is something other than :text
            # Insert a :text el as previous sibling
            ke.insert_sibling_before(Kramdown::ElementRt.new(:text, ' '))
          end
          # remove text node if it is now empty
          if ['', nil].include?(fc.value)
            fc.detach_from_parent
          end
        end
        lc = ke.children.last
        if lc && :text == lc.type && lc.value =~ /[ \n\t]+\z/
          # push out trailing whitespace
          lc.value.rstrip!
          if(foll_sib = ke.following_sibling) && (:text == foll_sib.type)
            # following sibling is :text el
            # Prepend trailing whitespace
            foll_sib.value.prepend(' ')
          else
            # following sibling doesn't exist or is something other than :text
            # Insert a :text el as followings sibling
            ke.insert_sibling_after(Kramdown::ElementRt.new(:text, ' '))
          end
          # remove text node if it is now empty
          if ['', nil].include?(lc.value)
            lc.detach_from_parent
          end
        end
      end
    end

  end
end
