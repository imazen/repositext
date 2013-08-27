# -*- encoding: utf-8 -*-

require 'kramdown/converter/html'

class Kramdown::Converter::Html

  def convert_subdoc(el, indent)
    format_as_indented_block_html('div', el.attr, inner(el, indent), indent)
  end

  def convert_line_synchro_marker(el, indent)
    "<span#{html_attributes(el.attr)}>%</span>"
  end

  def convert_word_synchro_marker(el, indent)
    "<span#{html_attributes(el.attr)}>@</span>"
  end

end
