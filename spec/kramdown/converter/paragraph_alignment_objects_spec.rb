require_relative '../../helper'

module Kramdown
  module Converter
    describe ParagraphAlignmentObjects do

      [
        [
          %(the body),
          [
            { contents: "the body\n", name: "1", type: :p },
          ]
        ]
      ].each_with_index do |(kramdown, expected), idx|
        it "converts example #{ idx + 1 } to paragraph alignment objects" do
          doc = Document.new(kramdown, { :input => 'KramdownRepositext' })
          doc.to_paragraph_alignment_objects.map { |e|
            e.to_hash
          }.must_equal expected
        end
      end

    end
  end
end
