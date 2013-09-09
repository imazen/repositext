# -*- encoding: utf-8 -*-

require 'kramdown/converter/html'
require 'kramdown/converter/kramdown'
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


module Kramdown
  module Converter
    class Kramdown

      # copied from original converter because the :subdoc element needs to be handled specially
      def convert(el, opts = {:indent => 0})
        res = send("convert_#{el.type}", el, opts)
        if ![:html_element, :li, :dd, :td, :subdoc].include?(el.type) && (ial = ial_for_element(el))
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

      def convert_subdoc(el, opts)
        if @options[:disable_subdoc]
          inner(el, opts)
        else
          ial = ial_for_element(el)
          "^^^#{ial ? " #{ial}" : ""}\n\n#{inner(el, opts)}"
        end
      end

      def convert_line_synchro_marker(el, opts)
        @options[:disable_sync_b] ? "" : "%"
      end

      def convert_word_synchro_marker(el, opts)
        @options[:disable_sync_a] ? "" : "@"
      end

    end
  end
end
