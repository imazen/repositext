module Kramdown
  module Converter
    class LatexRepositext
      # Include this module in latex converters that render record_marks
      module RenderRecordMarksMixin

        def convert_record_mark(el, opts)
          r = break_out_of_song(@inside_song)
          if @options[:disable_record_mark]
            r << inner(el, opts)
          else
            meta = %( id: #{ el.attr['id'] })
            r << "\\RtRecordMark{#{ meta }}#{ inner(el, opts) }"
          end
          r
        end

      end
    end
  end
end
