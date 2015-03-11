require 'kramdown/element'

module Kramdown
  class Element

    # Adds class to self. Classes are case insensitive, so we downcase them.
    # @param[String] a_class
    def add_class(a_class)
      a_class = a_class.to_s.strip
      return true  if('' == a_class || has_class?(a_class))
      self.attr['class'] = attr['class'].to_s
                                        .split(' ')
                                        .map(&:strip)
                                        .push(a_class)
                                        .uniq
                                        .sort
                                        .join(' ')
                                        .downcase
    end

    # Returns self's descendants as flat array
    def descendants
      children.inject([]) { |m,child|
        m << child
        m += child.descendants
      }
    end

    # Prints a summary of self on a single line
    # @param[Integer, optional] _indent_level
    # @param[Hash, optional] _options
    # @return[String]
    def element_summary(_indent_level = 0, _options = {})
      el_options = {
        :max_value_length => 80,
        :indent => '  '
      }.merge(_options)
      el_value = value || ''
      el_indent = el_options[:indent] * _indent_level
      case el_value
      when String, Symbol
        # Print  element's value (e.g., type :text)
        el_value = el_value.truncate_in_the_middle(el_options[:max_value_length])
        el_value = el_value.length > 0 ? el_value.inspect : nil
      when Kramdown::Utils::Entities::Entity
        # Print :entity's code_point
        el_value = "code_point: #{ el_value.code_point }"
      else
        # Raise on any other cases
        raise el_value.inspect
      end
      [
        el_indent,
        ":#{ type }",
        (attr.inspect  if attr && attr.any?),
        (options.inspect  if options && options.any?),
        el_value
      ].compact.join(" - ")
    end

    # Returns self's classes as array, sorted alphabetically
    def get_classes
      (attr['class'] || '').downcase.split(' ').sort
    end

    # Returns true if self has a_class
    # @param[String] a_class
    def has_class?(a_class)
      get_classes.any? { |e| e == a_class.strip.downcase }
    end

    # Returns a tree representation of self and its descendants.
    #   * One element per line
    #   * Indents nested elements
    #   * truncates long text values in the middle so that string boundaries can be inspected.
    #   * includes attr and options if present
    # @param[String, optional] output all output is collected recursively into this string
    # @param[Integer, optional] _indent_level used for recursion
    # @param[Hash, optional] _options
    #   * max_value_length - Any text longer than this will be truncated in the middle.
    #   * indent - Characters used for indentation.
    # @return[String] the tree representation
    def inspect_tree(output = '', _indent_level = 0, _options = {})
      if value.is_a?(Kramdown::Element)
        # Some elements (:footnote I think) store an element in their value attr.
        # Recurse over nested elements.
        value.inspect_tree(output, _indent_level, el_options)
      else
        output << element_summary(_indent_level, _options)
        output << "\n"
      end
      # Recurse over child elements
      children.each { |e| e.inspect_tree(output, _indent_level + 1, _options) }
      output
    end

    # Prints ancestry as tree
    def inspect_ancestry_tree(output = '', _indent_level = 0, _options = {})
      # Walk up ancestry first
      if parent
        parent.inspect_ancestry_tree(output, _indent_level + 1, _options)
      end
      output << element_summary(_indent_level, _options)
      output << "\n"
      output
    end

    # Returns true if self is of same element type as other_ke.
    # This is used e.g., to merge adjacent siblings
    # @param[Kramdown::Element] other_ke
    def is_of_same_type_as?(other_ke)
      type == other_ke.type &&
      attr.reject { |k,v| 'id' == k } == other_ke.attr.reject { |k,v| 'id' == k } &&
      options.reject { |k,v| :location == k } == other_ke.options.reject { |k,v| :location == k }
    end

    # Compares self recursively with other_ke
    # @param[Kramdown::Element] other_ke
    # @param[Array, optional] diffs a collector that is used during recursion to collect diffs
    # @param[Hash, optional] options
    # @return[Array<String>] an array with differences between the two
    def compare_with(other_ke, diffs = [], options = {})
      options = {
        :recursive => true
      }.merge(options)
      # compare type, value and attr. Ignore options
      if(
        type != other_ke.type ||
        attr != other_ke.attr ||
        value != other_ke.value
      )
        diffs << "Different element:\n#{ parent.inspect_tree } vs.\n#{ other_ke.inspect_tree }"
      end
      if options[:recursive]
        # remove blanks and other empty elements
        child_selector = lambda { |child_ke|
          !(
            :blank == child_ke.type ||
            (:text == child_ke.type && [nil, ''].include?(child_ke.value))
          )
        }
        own_children = children.find_all(&child_selector)
        other_children = other_ke.children.find_all(&child_selector)
        if own_children.size == other_children.size
          # compare each child
          matched_children = own_children.zip(other_children)
          matched_children.each do |(own_child, other_child)|
            own_child.compare_with(other_child, diffs, options)
          end
        else
          # record the fact that children are different, stop recursing
          diffs << "Different children:\n#{ inspect_tree } vs.\n#{ other_ke.inspect_tree }"
        end
      end
      diffs
    end

    # Removes class from self
    # @param[String] a_class
    def remove_class(a_class)
      self.attr['class'] = (attr['class'] || '').split(' ')
                                                .map { |e| e.gsub(/\A#{ a_class.strip }\z/, '') }
                                                .join(' ')
    end

    # Sets classes, overwriting any existing classes
    # @param[Array<String>] class_names
    def set_classes(class_names)
      self.attr['class'] = ''
      class_names.each { |e| add_class(e) }
    end

    # Returns plain_text version of self and all descendants
    # @param collector [String, optional] for recursive calls
    # @param return [String]
    def to_plain_text(collector = '')
      before, after = Kramdown::Converter::PlainText.convert_el(self)
      collector << before  if before
      # walk the tree
      children.each { |e| e.to_plain_text(collector) }
      collector << after  if after
      collector
    end

  end
end
