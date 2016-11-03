module Kramdown
  # Include this module into any library that wants to sanitize whitespace during import.
  # Preferrably call it after whitespace has been pushed out so that we can also
  # handle leading whitespace in the first :em inside a :p
  module ImportWhitespaceSanitizer

    # Recursively remove leading whitespace
    # @param [Kramdown::Element] ke
    def recursively_sanitize_whitespace_during_import!(ke)
      # Work from the bottom up so that tree mutations don't interfere with
      # iteration over children.
      # First iterate over children, use queue to decouple it from a parent's children
      # collection. This is important to make recursion work.
      ke_processing_queue = ke.children.dup # duplicate list with references to same objects
      while(ke_child = ke_processing_queue.shift) do
        recursively_sanitize_whitespace_during_import!(ke_child)
      end
      # Then do mutation on current ke at the end
      sanitize_whitespace_during_import!(ke)
    end

    # Sanitizes whitespace:
    # * replaces runs of [ \t] with single space to remove tabs and collapse runs
    #   of whitespace
    # * Removes leading and trailing whitespace inside a block element (operates on ke's
    #   children since we need the parent around, and this should work on regular
    #   Kramdown::Element, too)
    # NOTE: this doesn't do any recursion. It operates on a single ke only.
    # @param [Kramdown::Element] ke
    def sanitize_whitespace_during_import!(ke)
      case ke.type
      when :text
        # reduce runs of whitespace and tabs to single space
        ke.value.gsub!(/[ \t]+/, ' ')
      when :p, :header
        # Remove para or header outer whitespace
        # remove leading whitespace
        if(
          (fc = ke.children.first) &&
          :text == fc.type
        )
          fc.value.gsub!(/\A[ \t\n]+/, '')
          if '' == fc.value
            # remove :text el if it is now empty
            ke.children.delete_at(0)
            # process ke again since there may be new leading whitespace
            sanitize_whitespace_during_import!(ke)
          end
        end
        # remove trailing whitespace
        if(
          (lc = ke.children.last) &&
          :text == lc.type
        )
          lc.value.gsub!(/[ \t\n]+\z/, '')
          if '' == lc.value
            # remove :text el if it is now empty
            ke.children.delete_at(-1)
            # process ke again since there may be new trailing whitespace
            sanitize_whitespace_during_import!(ke)
          end
        end
      end
    end

  end
end
