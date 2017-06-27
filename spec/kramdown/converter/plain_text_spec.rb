require_relative '../../helper'

module Kramdown
  module Converter
    describe PlainText do

      # Specs that run with repositext because :
      # a) repositext can handle the element type OR
      # b) repositext's behavior is different from kramdown proper
      [
        [
          'Simple text',
          %(the body),
          %(the body)
        ],
        [
          'Level 1 header (without prefix)',
          %(# the header),
          %(the header)
        ],
        [
          'Level 2 header (without prefix)',
          %(## the header),
          %(the header)
        ],
        [
          'Level 3 header (without prefix)',
          %(### the header),
          %(the header)
        ],
        [
          'em',
          %(*the em*),
          %(the em)
        ],
        [
          'strong',
          %(**the strong**),
          %(the strong)
        ],
        [
          'two paragraphs',
          %(para 1\n\npara 2),
          %(para 1\npara 2)
        ],
        [
          'paragraph and horizontal rule',
          %(para 1\n\n***),
          %(para 1\n* * * * * * *)
        ],
        [
          'complex mix of elements',
          %(# header 1\n\n## header 2 *with em*\n\n### header 3\n\npara 1\n\npara 2 **with strong**.),
          %(header 1\nheader 2 with em\nheader 3\npara 1\npara 2 with strong.)
        ],
        [
          'paragraph between level 3 headers',
          %(# header 1\n\npara 1\n\n### header 3a\n\npara 2\n\n### header 3b\n\npara 3.),
          %(header 1\npara 1\nheader 3a\npara 2\nheader 3b\npara 3.)
        ],
        [
          'regression 1',
          "### @word\n\n@word word d.C.\n{: .normal}\n\n### @word\n\n@*2*{: .pn} word",
          "word\nword word d.C.\nword\n2 word"
        ],
        [
          'escaped brackets',
          %(some text with \\[escaped brackets\\]),
          %(some text with [escaped brackets])
        ],
        [
          'non-ascii char',
          %(some text with non-ascii char ),
          %(some text with non-ascii char )
        ],
      ].each_with_index do |(description, kramdown, expected), idx|
        it "handles #{ description }" do
          doc = Document.new(
            kramdown, { :input => 'KramdownRepositext' }
          )
          doc.to_plain_text.must_equal expected
        end
      end

      describe "option :convert_smcaps_to_upper_case" do

        let(:kramdown_with_em_smcaps){ "Word *Word word word*{: .smcaps} word."}

        it "leaves text alone if turned off (default)" do
          doc = Document.new(
            kramdown_with_em_smcaps, { input: 'KramdownRepositext' }
          )
          doc.to_plain_text.must_equal "Word Word word word word."
        end

        it "converts text to upper case inside em.smcaps if turned on" do
          doc = Document.new(
            kramdown_with_em_smcaps,
            { input: 'KramdownRepositext', convert_smcaps_to_upper_case: true }
          )
          doc.to_plain_text.must_equal "Word WORD WORD WORD word."
        end

      end

    end
  end
end
