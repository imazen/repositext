require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkSequenceSyntax do

        describe 'subtitle_mark_sequences_valid?' do

          it 'exits early on files that contain no subtitle_marks' do
            r_file = get_r_file(contents: 'text without subtitle_mark')
            v = SubtitleMarkSequenceSyntax.new(r_file, '_', '_', {})
            v.send(
              :subtitle_mark_sequences_valid?,
              r_file
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
              [["Space inside subtitle mark sequence:", 1, "@word @ @word word"]]
            ],
            [
              'Space between stm and trailing eagle',
              "@word @@@@ ",
              [["Space between subtitle mark and trailing eagle:", 1, "@word @@@@ "]]
            ],
          ].each do |description, test_string, xpect|
            it "handles #{ description }" do
              r_file = get_r_file(contents: test_string)
              v = SubtitleMarkSequenceSyntax.new(r_file, '_', '_', { })
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
