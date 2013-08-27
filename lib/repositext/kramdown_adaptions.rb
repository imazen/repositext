# -*- encoding: utf-8 -*-

require 'kramdown/converter/html'

class Kramdown::Converter::Html

  def convert_subdoc(el, indent)
    format_as_indented_block_html('div', el.attr, inner(el, indent), indent) unless @options[:disable_subdoc]
  end

  def convert_line_synchro_marker(el, indent)
    "<span class=\"sync-mark-b\"></span>" unless @options[:disable_sync_b]
  end

  def convert_word_synchro_marker(el, indent)
    "<span class=\"sync-mark-a\"></span>" unless @options[:disable_sync_a]
  end

  alias_method :convert_root_old, :convert_root
  def convert_root(el, indent)
    "<!-- #{Time.now.to_s} -->\n" + 
    "<!-- #{@options.inspect} -->\n" + 
    convert_root_old(el,indent)
  end 

end
