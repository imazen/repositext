require_relative '../../helper'

module Kramdown
  module Converter
    describe PlainText do

      # Specs that run with repositext because :
      # a) repositext can handle the element type OR
      # b) repositext's behavior is different from kramdown proper
      [
        [%(the body), %(the body)],
        [%(# the header), %(the header)],
        [%(## the header), %(the header)],
        [%(### the header), %(the header)],
        [%(*the em*), %(the em)],
        [%(**the strong**), %(the strong)],
        [%(para 1\n\npara 2), %(para 1\npara 2)],
        [%(para 1\n\n***), %(para 1\n* * * * * * *)],
        [
          %(# header 1\n\n## header 2 *with em*\n\npara 1\n\npara 2 **with strong**.),
          %(header 1\nheader 2 with em\npara 1\npara 2 with strong.)
        ],
        [%(some text with \\[escaped brackets\\]), %(some text with [escaped brackets])],
        [%(some text with non-ascii char ), %(some text with non-ascii char )],
      ].each_with_index do |(kramdown, expected), idx|
        it "converts example #{ idx + 1 } to plain text" do
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
