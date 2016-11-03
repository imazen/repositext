module Kramdown
  module Converter
    class ParagraphAlignmentObjects
      # Represents a block element for the purpose of aligning paragraphs
      class BlockElement

        # Names of attr_accessors
        ATTRIBUTE_NAMES = %i[
          contents
          ke_attrs
          key
          name
          position
          subtitle_mark_indexes
          type
        ].freeze

        attr_accessor *ATTRIBUTE_NAMES

        # @param attrs [Hash]
        def initialize(attrs)
          attrs.each do |k,v|
            self.send("#{ k }=", v)
          end
        end

        def to_hash
          ATTRIBUTE_NAMES.inject({}) { |m,e|
            v = self.send(e)
            m[e] = v  if v.present?
            m
          }
        end

        # Returns kramdown string for self
        # @param kramdown_converter [Class]
        def to_kramdown(kramdown_converter=nil)
          kramdown_converter ||= ::Kramdown::Converter::KramdownRepositext.send(
            :new, nil, {}
          )
          return ''  if :gap == type

          el = ::Kramdown::ElementRt.new(
            type,
            nil,
            ke_attrs,
            { category: :block, ial: ke_attrs }
          )
          # combine contents with block_ial. Normalize to two trailing newlines.
          (
            [
              contents,
              kramdown_converter.send(:ial_for_element, el),
              "\n\n"
            ].join
          ).gsub(/\n+\z/, "\n\n")
        end

      end
    end
  end
end
