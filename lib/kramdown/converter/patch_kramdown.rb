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

      # Patch this method to allow for nullop IAL {:s}
      # The purpose of nullop IALs is to allow unambigous rendering of adjacent
      # ems without whitespace separation.
      # Example:
      # *firstHalf**secondHalf*{: .smallCaps} is ambiguous without nullop IAL
      # *firstHalf*{:s}*secondHalf*{: .smallCaps}. Can be rendered unambiguously
      # Return the IAL containing the attributes of the element +el+.
      def ial_for_element(el)
        res = el.attr.map do |k,v|
          next if [:img, :a].include?(el.type) && ['href', 'src', 'alt', 'title'].include?(k)
          next if el.type == :header && k == 'id' && !v.strip.empty?
          if :nullop == k && v.nil?
            :nullop
          elsif v.nil?
            ''
          elsif k == 'class' && !v.empty?
            " " + v.split(/\s+/).map {|w| ".#{w}"}.join(" ")
          elsif k == 'id' && !v.strip.empty?
            " ##{v}"
          else
            " #{k}=\"#{v.to_s}\""
          end
        end.compact
        if (el.type == :ul || el.type == :ol) && (el.options[:ial][:refs].include?('toc') rescue nil)
          res.unshift(" toc")
        end
        res = if [:nullop] == res
          # nullop is the only item, keep it and convert to 's'
          ['s']
        else
          # discard nullop item since we have other items that will trigger rendering of IAL
          res - [:nullop]
        end
        res = res.join('')
        res.strip.empty? ? nil : "{:#{res}}"
      end

    end
  end
end
