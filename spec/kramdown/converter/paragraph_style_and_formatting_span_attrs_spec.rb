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
              :index=>0,
              :type=>:p,
              :paragraph_styles=>[],
              :plain_text_contents=> "the body"
            }
          ]
        ],
        [
          'Para with ial and em',
          %(first para *word* word2.\n{: .normal}),
          [
            {
              :formatting_spans=>[:italic],
              :index=>0,
              :type=>:p,
              :paragraph_styles=>["normal"],
              :plain_text_contents=>"first para word word2."
            }
          ]
        ],
        [
          'Multiple paragraphs',
          %(para1\n{: .normal}\n\n2 para2\n{: .normal_pn}),
          [
            {
              :formatting_spans=>[],
              :index=>0,
              :type=>:p,
              :paragraph_styles=>['normal'],
              :plain_text_contents=>"para1"
            },
            {
              :formatting_spans=>[],
              :index=>1,
              :type=>:p,
              :paragraph_styles=>['normal_pn'],
              :plain_text_contents=>"2 para2"
            },
          ]
        ],
        [
          'Multiple em classes',
          %(word1 *word2*{: .smcaps.italic} word3),
          [
            {
              :formatting_spans=>[:italic, :smcaps],
              :index=>0,
              :type=>:p,
              :paragraph_styles=>[],
              :plain_text_contents=>"word1 word2 word3"
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
