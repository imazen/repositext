require_relative '../../helper'

module Kramdown
  module Converter
    describe ParagraphAlignmentObjects do

      [
        [
          'Basic example',
          %(the body),
          [
            { contents: "the body\n", name: "1", type: :p },
          ]
        ],
        [
          'No escaping of period after digit at beginning of line (The kramdown :p converter escapes the period in "1. word" to "1\\. word")',
          %(1. word word),
          [
            { contents: "1. word word\n", name: "1", type: :p },
          ]
        ],
      ].each do |(description, kramdown, xpect)|
        it "handles #{ description }" do
          doc = Document.new(kramdown, { :input => 'KramdownRepositext' })
          doc.to_paragraph_alignment_objects.map { |e|
            e.to_hash
          }.must_equal(xpect)
        end
      end

    end
  end
end
