require 'kramdown/element'

module Kramdown
  class Element

    # Returns a tree representation of self, including all descendants.
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
      el_options = {
        :max_value_length => 80,
        :indent => '  '
      }.merge(_options)
      el_indent = el_options[:indent] * _indent_level
      el_value = value || ''
      case el_value
      when String, Symbol
        # Print  element's value (e.g., type :text)
        if el_value.length > el_options[:max_value_length]
          # long string, truncate in the middle, preserve start and end.
          half_len = el_options[:max_value_length]/2
          el_value = "#{ el_value[0..half_len] } [...] #{ el_value[-half_len..-1] }"
        end
        el_value = el_value.length > 0 ? el_value.inspect : nil
        output << [
          el_indent,
          ":#{ type }",
          (attr.inspect  if attr && attr.any?),
          (options.inspect  if options && options.any?),
          el_value
        ].compact.join(" - ")
        output << "\n"
      when Kramdown::Element
        # Some elements (:footnote I think) store an element in their value attr.
        # Recurse over nested elements.
        el_value.inspect_tree(output, _indent_level + 1, el_options)
      when Kramdown::Utils::Entities::Entity
        # Print :entity's code_point
        output [
          el_indent,
          ":#{ type }",
          (attr.inspect  if attr && attr.any?),
          (options.inspect  if options && options.any?),
          "code_point: #{ el_value.code_point }"
        ].compact.join(" - ")
        output << "\n"
      else
        # Raise on any other cases
        raise el_value.inspect
      end
      # Recurse over child elements
      children.each { |e| e.inspect_tree(output, _indent_level + 1, el_options) }
      output
    end

  end
end
