# -*- encoding: utf-8 -*-

require 'kramdown/converter/html'
require 'kramdown/options'

module Kramdown::Options
  define(:disable_sync_a, Boolean, false, "Some documentation for the option")
  define(:disable_sync_b, Boolean, false, "Some documentation for the option")
  define(:disable_subdoc, Boolean, false, "Some documentation for the option")
end

class Kramdown::Converter::Html

  def convert_subdoc(el, indent)
    @options[:disable_subdoc] ? inner(el, indent) : format_as_indented_block_html('div', el.attr, inner(el, indent), indent) 
  end

  def convert_line_synchro_marker(el, indent)
    @options[:disable_sync_b] ? "" : "<span class=\"sync-mark-b\"></span>"
  end

  def convert_word_synchro_marker(el, indent)
    @options[:disable_sync_a] ? "" : "<span class=\"sync-mark-a\"></span>"  
  end

  alias_method :convert_root_old, :convert_root
  def convert_root(el, indent)
    "<!-- #{Time.now.to_s} -->\n" + 
    "<!-- #{@options.inspect} -->\n" + 
    convert_root_old(el,indent)
  end 

end
