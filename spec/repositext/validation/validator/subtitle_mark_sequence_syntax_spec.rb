require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkSequenceSyntax do

        describe 'subtitle_mark_sequences_valid?' do

          it 'exits early on files that contain no subtitle_marks' do
            v = SubtitleMarkSequenceSyntax.new('_', '_', '_', {})
            v.send(
              :subtitle_mark_sequences_valid?,
              'text without subtitle_mark'
            ).success.must_equal(true)
          end

        end

        describe 'find_invalid_subtitle_mark_sequences' do
          [
            [
              "Valid sequence",
              "@word word @@@word",
              [],
            ],
            [
              'Space inside sequence',
              "@word @ @word word",
              [["Space inside subtitle mark sequence:", "line 1", "@word @ @word word"]]
            ],
            [
              'Space between stm and trailing eagle',
              "@word @@@@ ",
              [["Space between subtitle mark and trailing eagle:", "line 1", "@word @@@@ "]]
            ],
          ].each do |description, test_string, xpect|
            it "handles #{ description }" do
              v = SubtitleMarkSequenceSyntax.new('_', '_', '_', { })
              v.send(
                :find_invalid_subtitle_mark_sequences,
                test_string
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
