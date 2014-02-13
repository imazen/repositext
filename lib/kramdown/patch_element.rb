require 'kramdown/element'

module Kramdown
  class Element

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
        if el_value.length > el_options[:max_value_length]
          # long string, truncate in the middle, preserve start and end.
          half_len = el_options[:max_value_length]/2
          el_value = "#{ el_value[0..half_len] } [...] #{ el_value[-half_len..-1] }"
        end
        el_value = el_value.length > 0 ? el_value.inspect : nil
        [
          el_indent,
          ":#{ type }",
          (attr.inspect  if attr && attr.any?),
          (options.inspect  if options && options.any?),
          el_value
        ].compact.join(" - ")
      when Kramdown::Utils::Entities::Entity
        # Print :entity's code_point
        [
          el_indent,
          ":#{ type }",
          (attr.inspect  if attr && attr.any?),
          (options.inspect  if options && options.any?),
          "code_point: #{ el_value.code_point }"
        ].compact.join(" - ")
      else
        # Raise on any other cases
        raise el_value.inspect
      end
    end

  end
end
