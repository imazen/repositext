module Caracal
  module Renderers
    class StylesRenderer < XmlRenderer

      # This patch allows hanging indents. If indent_first is negative, it will
      # be specified as a hanging indent. If it is positive, it will be used as
      # firstLine indent.
      def indentation_options(style, default=false)
        left    = (default) ? style.style_indent_left.to_i  : style.style_indent_left
        right   = (default) ? style.style_indent_right.to_i : style.style_indent_right
        first   = (default) ? style.style_indent_first.to_i : style.style_indent_first
        options = nil
        if [left, right, first].compact.size > 0
          options                  = {}
          options['w:left']        = left    unless left.nil?
          options['w:right']       = right   unless right.nil?
          # Start patch JH
          if first
            if first >= 0
              options['w:firstLine'] = first
            elsif first < 0
              options['w:hanging'] = first * -1
            else
              raise "Handle this: #{ first.inspect }"
            end
          end
        end
        options
      end

    end
  end
end
