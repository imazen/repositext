# Adds behavior to Kramdown::Element that is required for Folio XML import (Repositext)
#
module Kramdown
  class ElementRt < Element

    attr_accessor :parent # points to parent Kramdown::Element or nil for root

    # API to add children to self. This takes care of setting each child's
    # parent attr to self.
    # @param[Array<Kramdown::Element>] the_children
    def add_children(the_children)
      the_children.each { |e| e.parent = self }
      self.children += the_children
    end
    # @param[Kramdown::Element] the_child
    def add_child(the_child); add_children([the_child]); end

    # Returns true if self has a_class
    # @param[String] a_class
    def has_class?(a_class)
      (attr['class'] || '').split(' ').any? { |e| e == a_class }
    end

    # Adds class to self
    # @param[String] a_class
    def add_class(a_class)
      return true  if has_class?(a_class)
      if attr['class'] && attr['class'] != ''
        self.attr['class'] << " #{ a_class }"
      else
        self.attr['class'] = a_class
      end
    end

    # Removes class from self
    # @param[String] a_class
    def remove_class(a_class)
      return true if !has_class?(a_class)
      self.attr['class'] = attr['class'].gsub(a_class, '')
    end
  end
end
