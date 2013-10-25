require 'kramdown/converter/html'

class Kramdown::Converter::Html

  def convert_record_mark(el, indent)
    @options[:disable_record_mark] ? inner(el, indent - @indent) : format_as_indented_block_html('div', el.attr, inner(el, indent), indent)
  end

  def convert_gap_mark(el, indent)
    @options[:disable_gap_mark] ? "" : "<span class=\"sync-mark-b\"></span>"
  end

  def convert_subtitle_mark(el, indent)
    @options[:disable_subtitle_mark] ? "" : "<span class=\"sync-mark-a\"></span>"
  end

  # Add converter for ems:
  # In IDML em are used as container to apply a class to a span. It's a container
  # if it has a class (to emulate a SPAN for applying styles). Will be rendered
  # italic only if it has italic class. Bare em elements are interpreted as
  # emphasis and will be displayed in italic.


  alias_method :convert_root_old, :convert_root
  def convert_root(el, indent)
    # "<!-- #{Time.now.to_s} -->\n" +
    # "<!-- #{@options.inspect} -->\n" +
    convert_root_old(el,indent)
  end

end

