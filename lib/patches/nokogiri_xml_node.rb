module Nokogiri
  module XML
    class Node

      # Recursive method to print the name and class path for self
      # @param[String, optional] downstream_path (used for recursion)
      def name_and_class_path(downstream_path = '')
        downstream_path = name_and_class + downstream_path
        if parent && !parent.xml?
          # Recurse to parent unless it's the top level XML Document node (.xml?)
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

      # Returns true if other_xn has same name, class, and type as self
      # @param[Nokogiri::Xml::Node] other_xn
      def duplicate_of?(other_xn)
        name == other_xn.name &&
        %w[class type].all? { |attr|
          ![nil, ''].include?(self[attr]) &&
          self[attr] == other_xn[attr]
        }
      end

    end
  end
end
