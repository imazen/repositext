# Adds behavior to Kramdown::Element that is required for Folio XML import (Repositext)
#
require 'kramdown/element'

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

    # Below are sketches of methods we may want to add in the future. Don't
    # need them right now

    # # API to remove children from self. This takes care of removing self's children
    # # references to the_children.
    # # @param[Array<Kramdown::Element>] the_children
    # def remove_children(the_children)
    #   self.children = children - the_children
    # end
    # # @param[Kramdown::Element] the_child
    # def remove_child(the_child); remove_children([the_child]); end

    # # Traverses ancestry until it finds an element that matches criteria.
    # # Returns that ancestor or nil if none found.
    # # @param[Hash] criteria, keys are methods to send to element,
    # #                        vals are expected output. Example: { :type => :record }
    # # @return[Kramdown::Element, nil]
    # def find_ancestor_element(criteria)
    #   if(criteria.all? { |k,v| self.send(k) == v })
    #     self # self matches criteria, return it
    #   elsif parent.nil?
    #     nil # no more parents, return nil
    #   else
    #     parent.find_ancestor(criteria) # delegate to parent
    #   end
    # end

    # # Removes self as link between parent and children and promotes self's children
    # # to parent's children
    # # @return[Array<Kramdown::Element] self's children if any.
    # def pull
    #   # Can't pull root
    #   raise(ArgumentError, "Cannot pull root node: #{ self.inspect }")  if parent.nil?
    #   parent.remove_child(self)
    #   parent.add_children(children)
    #   children
    # end

    # # Removes self and all descendants from document
    # # @return[Kramdown::Element] self
    # def drop
    #   # Can't drop root
    #   raise(ArgumentError, "Cannot pull root node: #{ self.inspect }")  if parent.nil?
    #   parent.remove_child(self)
    #   self
    # end

    # def find_descendants(criteria)
    #   # we may need this.
    # end

    # def find_ancestor_record_mark_element
    #   find_ancestor_element(:type => :record_mark)
    # end

    # def find_ancestor_p_element
    #   find_ancestor_element(:type => :paragraph)
    # end

  end
end
