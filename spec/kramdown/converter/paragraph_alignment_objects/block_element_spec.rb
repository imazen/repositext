require_relative '../../../helper'

module Kramdown
  module Converter
    class ParagraphAlignmentObjects
      describe BlockElement do

        [
          [
            { contents: "the body", name: "1", type: :p },
            %(the body\n\n),
          ]
        ].each_with_index do |(attrs, expected), idx|
          it "converts example #{ idx + 1 } to kramdown" do
            t = BlockElement.new(attrs)
            t.to_kramdown.must_equal(expected)
          end
        end

      end
    end
  end
end
