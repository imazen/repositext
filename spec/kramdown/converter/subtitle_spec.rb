require_relative '../../helper'

module Kramdown
  module Converter
    describe Subtitle do

      describe '#post_process_output' do

        [
          ["^^^\n\n# header\n\nfirst para\n\nsecond para", "[|# header|]\n\n@first para\n\nsecond para\n"],
          ["^^^\n\n# header\n\n[first para as editors note]\n\nsecond para", "[|# header|]\n\n@[first para as editors note]\n\nsecond para\n"],
        ].each do |(test_string, xpect)|
          it "adds a subtitle to beginning of first para if doc doesn't contain any '@'" do
            doc = Document.new(test_string, :input => 'KramdownRepositext')
            doc.to_subtitle.must_equal(xpect)
          end
        end

        it "doesn't add a subtitle to beginning of first para if doc already contains any '@'" do
          doc = Document.new("^^^\n\n# header\n\nthe first @para", :input => 'KramdownRepositext')
          doc.to_subtitle.must_equal "[|# header|]\n\nthe first @para\n"
        end

      end

    end
  end
end
