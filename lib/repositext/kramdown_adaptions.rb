# -*- encoding: utf-8 -*-

require 'kramdown/converter/html'
require 'kramdown/converter/kramdown'
require 'kramdown/options'

module Kramdown::Options
  define(:disable_subtitle_mark, Boolean, false, "Some documentation for the option")
  define(:disable_gap_mark, Boolean, false, "Some documentation for the option")
  define(:disable_record_mark, Boolean, false, "Some documentation for the option")
end

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

  alias_method :convert_root_old, :convert_root
  def convert_root(el, indent)
    # "<!-- #{Time.now.to_s} -->\n" +
    # "<!-- #{@options.inspect} -->\n" +
    convert_root_old(el,indent)
  end

end


module Kramdown
  module Converter
    class Kramdown

      # copied from original converter because the :record_mark element needs to be handled specially
      def convert(el, opts = {:indent => 0})
        res = send("convert_#{el.type}", el, opts)
        if ![:html_element, :li, :dd, :td, :record_mark].include?(el.type) && (ial = ial_for_element(el))
          res << ial
          res << "\n\n" if Element.category(el) == :block
        elsif [:ul, :dl, :ol, :codeblock].include?(el.type) && opts[:next] &&
            ([el.type, :codeblock].include?(opts[:next].type) ||
             (opts[:next].type == :blank && opts[:nnext] && [el.type, :codeblock].include?(opts[:nnext].type)))
          res << "^\n\n"
        elsif Element.category(el) == :block &&
            ![:li, :dd, :dt, :td, :th, :tr, :thead, :tbody, :tfoot, :blank].include?(el.type) &&
            (el.type != :html_element || @stack.last.type != :html_element) &&
            (el.type != :p || !el.options[:transparent])
          res << "\n"
        end
        res
      end

      def convert_record_mark(el, opts)
        if @options[:disable_record_mark]
          inner(el, opts)
        else
          ial = ial_for_element(el)
          "^^^#{ial ? " #{ial}" : ""}\n\n#{inner(el, opts)}"
        end
      end

      def convert_gap_mark(el, opts)
        @options[:disable_gap_mark] ? "" : "%"
      end

      def convert_subtitle_mark(el, opts)
        @options[:disable_subtitle_mark] ? "" : "@"
      end

    end
  end
end
