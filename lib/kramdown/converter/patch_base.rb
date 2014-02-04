# -*- encoding: utf-8 -*-
require 'kramdown/converter/base'

module Kramdown
  module Converter
    class Base

      # Unescapes brackets in a_text
      # @param[String] a_text
      # @return[String] the text with unescaped brackets
      def unescape_brackets(a_text)
        a_text.gsub(/\\([\[\]])/) { |match| $1 }
      end

    end
  end
end

# TODO: use tilt for templating, override Kramdown::Converter::Base#apply_template
# Look at hardwired's templating: has stack of templates
# https://github.com/nathanaeljones/hardwired/blob/master/lib/hardwired/page.rb#L177
