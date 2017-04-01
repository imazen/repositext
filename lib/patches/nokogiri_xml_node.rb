module Nokogiri
  module XML
    class Node

      # Adds class_name to own classes
      # @param class_name [String]
      def add_class(class_name)
        self['class'] = (class_names << class_name.strip).uniq.join(' ')
      end

      # Returns own classes
      # @return [Array<String>]
      def class_names
        (self['class'] || '').split(' ')
      end

      # Returns true if other_xn has same name, class, and type as self
      # @param [Nokogiri::Xml::Node] other_xn
      def duplicate_of?(other_xn)
        name == other_xn.name &&
        %w[class type].all? { |attr|
          ![nil, ''].include?(self[attr]) &&
          self[attr] == other_xn[attr]
        }
      end

      # Returns true if self has a_class.
      # @param a_class [String]
      # @return [Boolean]
      def has_class?(a_class)
        class_names.include?(a_class)
      end

      # Recursive method to print the name and class path for self
      # @param [String, optional] downstream_path (used for recursion)
      def name_and_class_path(downstream_path = '')
        downstream_path = name_and_class + downstream_path
        if respond_to?(:parent) && parent && !parent.xml?
          # Recurse to parent unless it's the top level XML Document node (.xml?)
          # or top level HTML Document node (doesn't respond to parent)
          parent.name_and_class_path(' > ' + downstream_path)
        else
          # This is the top level node
          return downstream_path
        end
      end

      # Returns name and class of self in CSS notation
      def name_and_class
        [name, self['class']].compact.join('.')
      end

      # Removes class_name from own classes
      # @param class_name [String]
      def remove_class(class_name)
        self['class'] = class_names.reject{ |e| e == class_name.strip}.join(' ')
      end

      # Wraps self in parent.
      # NOTE: There is an open pull request on Github to implement this:
      #   https://github.com/sparklemotion/nokogiri/pull/1531
      # @param parent_xn [Nokogiri::XML::Node]
      # @return [self]
      def wrap_in(parent_xn)
        add_next_sibling(parent_xn)
        parent_xn.add_child(self)
        self
      end

    end
  end
end
