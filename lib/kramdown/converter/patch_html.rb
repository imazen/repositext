require 'kramdown/converter/html'

class Kramdown::Converter::Html

  def convert_record_mark(el, indent)
    @options[:disable_record_mark] ? inner(el, indent - @indent) : format_as_indented_block_html('div', el.attr, inner(el, indent), indent)
  end

  def convert_gap_mark(el, indent)
    @options[:disable_gap_mark] ? "" : "<span class=\"gap-mark\"></span>"
  end

  def convert_subtitle_mark(el, indent)
    @options[:disable_subtitle_mark] ? "" : "<span class=\"subtitle-mark\"></span>"
  end

  # Patch this method to handle ems that came from idml docs:
  # When importing IDML, :ems are used as container to apply a class to a span.
  def convert_em(el, indent)
    case
    when 'strong' == el.type
      # nothing special here. alias :strong. need this?
      format_as_span_html(el.type, el.attr, inner(el, indent))
    when [nil, ''].include?(el.attr['class'])
      # em without class => convert to <em> element
      format_as_span_html(el.type, el.attr, inner(el, indent))
    when el.attr['class'] =~ /\bitalic\b/
      # em with classes, including .italic => convert to <em> with classes added
      format_as_span_html(el.type, el.attr, inner(el, indent))
    when el.attr['class'] !=~ /\bitalic\b/
      # em with classes, excluding .italic => convert to <span> with classes added
      format_as_span_html(:span, el.attr, inner(el, indent))
    else
      raise("Handle this: el.inspect")
    end
  end

  # Patch this method to unescape_brackets
  def convert_text(el, indent)
    escape_html(unescape_brackets(el.value), :text)
  end

end
