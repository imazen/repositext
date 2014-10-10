require_relative '../../helper'

module Kramdown
  module Converter
    describe Subtitle do

      describe '#post_process_output' do

        it "adds a subtitle to beginning of first para if doc doesn't contain any '@'" do
          doc = Document.new("^^^\n\n# header\n\nfirst para\n\nsecond para", :input => 'KramdownRepositext')
          doc.to_subtitle.must_equal "[|# header|]\n\n@first para\n\nsecond para\n"
        end

        it "doesn't add a subtitle to beginning of first para if doc already contains any '@'" do
          doc = Document.new("^^^\n\n# header\n\nthe first @para", :input => 'KramdownRepositext')
          doc.to_subtitle.must_equal "[|# header|]\n\nthe first @para\n"
        end

      end

    end
  end
end
