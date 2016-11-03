module Kramdown
  # Include this module into any library that parses raw text during import.
  module RawTextParser

      include ::Kramdown::Utils::Entities

      # Processes and adds elements for raw_text as children to tree.
      # This method is inspired by Kramdown::Parser::Base#add_text and
      # Kramdown::Parser::Html#process_text
      # @param raw_text [String]
      # @param tree [Kramdown::Element, optional] the current kramdown element
      # @param type [Symbol, optional] @text_type defaults to :text
      # @return [Kramdown::Element] tree with new children for raw_text added
      def process_and_add_text(raw_text, tree = @tree, type = @text_type)
        return tree  if [nil, ''].include?(raw_text)
        # initialize variables in method scope
        current_text_element = nil
        new_el_opts = nil
        if tree.children.last && tree.children.last.type == type
          current_text_element = tree.children.last # Use existing text_element
        end

        # Prepare options for new kramdown_elements
        new_el_opts = (l = tree.options[:location]) ? { :location => l } : {}
        # Parse raw_text for multibyte characters
        # TODO: refactor this into a constant
        multibyte_char_re = /[\u00A0\u200B\u2011\u2028\u202F\uFEFF]/
        src = Kramdown::Utils::StringScanner.new(raw_text)
        while !src.eos?
          if current_text_element.nil?
            current_text_element = ElementRt.new(
              type,
              '',
              nil,
              new_el_opts
            )
            tree.add_child(current_text_element)
          end
          if tmp = src.scan_until(/(?=#{ multibyte_char_re })/)
            current_text_element.value << tmp
            mbc = src.scan(multibyte_char_re)
            val = mbc.codepoints.first
            tree.add_child(
              ElementRt.new(
                :entity,
                entity(val),
                nil,
                new_el_opts.merge(
                  :original => Repositext::Utils::EntityEncoder.encode(src.matched)
                )
              )
            )
            current_text_element = nil # reset cte so that a new one is created
          else
            current_text_element.value << src.rest
            src.terminate
          end
        end
        tree
      end

  end
end
