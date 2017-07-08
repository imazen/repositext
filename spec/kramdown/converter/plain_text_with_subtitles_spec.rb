require_relative '../../helper'

module Kramdown
  module Converter
    describe PlainTextWithSubtitles do

      [
        [%(@the @body), %(@the @body)],
        [%(@word1 word2 @word3 word4\n\n@word5 word6), %(@word1 word2 @word3 word4\n\n@word5 word6)],
      ].each_with_index do |(kramdown, expected), idx|
        it "converts example #{ idx + 1 } to plain text with subtitles" do
          doc = Document.new(
            kramdown, { :input => 'KramdownRepositext' }
          )
          doc.to_plain_text_with_subtitles.must_equal expected
        end
      end

    end
  end
end
