# Include this module into any library that wants to process :em elements that
# are nested inside other :em elements.

module Kramdown
  module NestedEmsProcessor

    # Processes ems inside other ems
    def clean_up_nested_ems!(ke)
      # First iterate over children
      ke.children.each { |cke| clean_up_nested_ems!(cke) }
      # Then do mutation on current ke at the end
      if :em == ke.type && ke.children.any? { |cke| :em == cke.type }
        # ke has at least one child :em
        ke_child_processing_queue = ke.children.dup # copy references to elements in collection
        found_child_em = nil
        new_parent_for_following_siblings = nil
        while(ke_child = ke_child_processing_queue.shift) do
          if :em == ke_child.type && !found_child_em
            # Found first child with tmp_class_name
            found_child_em = ke_child
            # ke_child is nested inside :em, do the magic
            if ke_child.is_only_child?
              # Scenario 1:
              #  CONVERT THIS                          INTO    THIS
              #  - :em [ke]                                     -> (pulled)
              #    - :em - {"class"=>"smcaps"} [ke_child]       -> :em - {"class"=>"smcaps italic"}
              #      - :text - "He called me"                   ->   - :text - "He called me"
              # * replace ke with ke_child, add .italic class to ke_child
              ke_child.add_class('italic')
              ke.replace_with(ke_child)
            else
              # Scenario 2:
              #  CONVERT THIS                          INTO    THIS
              #  - :em [ke]                                     -> - :em
              #    - :text - "This day "                        ->   - :text - "This day "
              #    - :em - {"class"=>"smcaps"} [ke_child]       -> - :em - {"class"=>"smcaps italic"}
              #      - :text - "has"                            ->   - :text - "has"
              #                                                 -> - :em
              #    - :text - " this "                           ->   - :text - " this "
              #    - :em - {"class"=>"tmpNoItalics"}            ->   - :em - {"class"=>"tmpNoItalics"}
              #      - :text - "word been"                      ->     - :text - "word been"
              # * leave ke_child's previous siblings alone
              # * make ke_child following sibling of ke, add class 'italic'
              # * make ke_child's following siblings children of new_parent_for_following_siblings
              #   (which is a following sibling of ke_child)
              ke_child.add_class('italic')
              ke.insert_sibling_after(ke_child)
            end
          elsif found_child_em
            # Following siblings, add as children to new_parent_for_following_siblings
            if new_parent_for_following_siblings.nil?
              # create new detached element (no parent, no children)
              new_parent_for_following_siblings = Kramdown::ElementRt.new(
                ke.type,
                ke.value,
                ke.attr,
                ke.options
              )
              # Add new_parent_for_following_siblings as sibling after found_child_em
              found_child_em.insert_sibling_after(new_parent_for_following_siblings)
            end
            # re-parent ke_child to new_parent_for_following_siblings
            new_parent_for_following_siblings.add_child(ke_child)
          else
            # ke_child's previous sibling, nothing to do
          end
        end
      end
    end

  end
end
