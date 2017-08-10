require_relative '../../helper'

module Kramdown
  module Converter
    describe ParagraphStyleAndFormattingSpanAttrs do

      [
        [
          'Basic example',
          %(the body),
          [
            {
              :formatting_spans=>[],
              :type=>:p,
              :paragraph_classes=>[],
              :line_number=>1,
            }
          ]
        ],
        [
          'Para with ial and em',
          %(first para *word* word2.\n{: .normal}),
          [
            {
              :formatting_spans=>[:italic],
              :type=>:p,
              :paragraph_classes=>["normal"],
              :line_number=>1,
            }
          ]
        ],
        [
          'Multiple paragraphs',
          %(para1\n{: .normal}\n\n2 para2\n{: .normal_pn}),
          [
            {
              :formatting_spans=>[],
              :type=>:p,
              :paragraph_classes=>['normal'],
              :line_number=>1,
            },
            {
              :formatting_spans=>[],
              :type=>:p,
              :paragraph_classes=>['normal_pn'],
              :line_number=>4,
            },
          ]
        ],
        [
          'Multiple em classes',
          %(word1 *word2*{: .smcaps.italic} word3),
          [
            {
              :formatting_spans=>[:italic, :smcaps],
              :type=>:p,
              :paragraph_classes=>[],
              :line_number=>1,
            }
          ]
        ],
      ].each do |(description, kramdown, xpect)|
        it "handles #{ description }" do
          doc = Document.new(kramdown, { :input => 'KramdownRepositext' })
          doc.to_paragraph_style_and_formatting_span_attrs.must_equal(xpect)
        end
      end

    end
  end
end
