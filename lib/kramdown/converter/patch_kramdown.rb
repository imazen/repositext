# -*- encoding: utf-8 -*-
require 'kramdown/converter/kramdown'

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

      # Override this method to always convert entities to their numeric representation.
      # Kramdown defaults to converting them to their character representation.
      def convert_entity(el, opts)
        "&##{ el.value.code_point };"
      end

    end
  end
end
