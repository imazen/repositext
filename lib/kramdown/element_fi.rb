# Adds behavior to Kramdown::Element that is required for Folio XML import
#
module Kramdown
  class ElementFi < Element

    attr_accessor :parent # points to parent Kramdown::Element or nil for root

    # API to add children to self. This takes care of setting each child's
    # parent attr to self.
    # @param[Kramdown::Element, Array<Kramdown::Element>] new_children single child or array thereof
    def add_children(new_children)
      new_children.each { |e| e.parent = self }
      self.children += new_children
    end
    def add_child(new_child); add_children([new_child]); end

    # Traverses ancestry until it finds an element that matches criteria.
    # Returns that ancestor or nil if none found.
    # @param[Hash] criteria, keys are methods to send to element,
    #                        vals are expected output. Example: { :type => :record }
    # @return[Kramdown::Element, nil]
    def find_ancestor(criteria)
      if(criteria.all? { |k,v| self.send(k) == v })
        self # self matches criteria, return it
      elsif parent.nil?
        nil # no more parents, return nil
      else
        parent.find_ancestor(criteria) # delegate to parent
      end
    end

    def find_descendants(criteria)
      # we may need this.
    end

    def containing_record
      find_ancestor(:type => :record)
    end

    def containing_paragraph
      find_ancestor(:type => :paragraph)
    end

    def add_class
    end

    def remove_class
    end

  end
end
