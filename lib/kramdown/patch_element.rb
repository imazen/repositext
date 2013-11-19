module Kramdown
  class Element

    # Prints a tree representation of self, including all descendants. Uses
    # `puts` to print output.
    # @param[Integer, optional] _indent_level used for recursion
    # @param[Hash, optional] _options
    def inspect_tree(_indent_level = 0, _options = {})
      el_options = {
        :max_value_length => 80,
        :indent => '  '
      }.merge(_options)
      el_indent = el_options[:indent] * _indent_level
      el_value = value || ''
      case el_value
      when String, Symbol
        if el_value.length > el_options[:max_value_length]
          # long string, truncate in the middle, preserve start and end.
          half_len = el_options[:max_value_length]/2
          el_value = "#{ el_value[0..half_len] }...#{ el_value[(-1 * half_len)..-1] }"
        end
        el_value = el_value.length > 0 ? el_value.inspect : nil
        puts [
          el_indent,
          ":#{type}",
          (attr.inspect  if attr && attr.any?),
          (options.inspect  if options && options.any?),
          el_value
        ].compact.join(" - ")
      when Kramdown::Element
        el_value.inspect_tree(_indent_level + 1, el_options)
      when Kramdown::Utils::Entities::Entity
        puts [
          el_indent,
          ":#{type}",
          (attr.inspect  if attr && attr.any?),
          (options.inspect  if options && options.any?),
          "code_point: #{el_value.code_point}"
        ].compact.join(" - ")
      else
        raise el_value.inspect
      end
      children.each { |e| e.inspect_tree(_indent_level + 1, el_options) }
    end

  end
end
