require_relative '../../helper'

module Kramdown
  module Converter
    describe SubtitleTagging do

      describe '#post_process_output' do

        it "doesn't add a subtitle to beginning of first para if doc doesn't contain any '@'" do
          doc = Document.new("^^^\n\n# header\n\nfirst para\n\nsecond para", :input => 'KramdownRepositext')
          doc.to_subtitle_tagging.must_equal "[|# header|]\n\nfirst para\n\nsecond para\n"
        end

      end

      describe 'handling of subtitle_marks' do

        it "removes any subtitle_marks the doc already contains" do
          doc = Document.new("^^^\n\n# header\n\nthe first @para", :input => 'KramdownRepositext')
          doc.to_subtitle_tagging.must_equal "[|# header|]\n\nthe first para\n"
        end

      end
    end
  end
end
