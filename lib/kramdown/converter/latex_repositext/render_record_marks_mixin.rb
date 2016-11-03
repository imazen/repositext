module Kramdown
  module Converter
    class LatexRepositext
      # Include this module in latex converters that render record_marks.
      module RenderRecordMarksMixin

        # @param el [Kramdown::Element]
        # @param opts [Hash{Symbol => Object}]
        def convert_record_mark(el, opts)
          if @options[:disable_record_mark]
            inner(el, opts)
          else
            meta = %( id: #{ el.attr['id'] })
            "\\RtRecordMark{#{ meta }}#{ inner(el, opts) }"
          end
        end

      end
    end
  end
end
