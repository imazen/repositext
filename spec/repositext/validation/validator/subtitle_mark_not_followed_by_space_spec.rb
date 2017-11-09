require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkNotFollowedBySpace do

        describe 'no_subtitle_marks_followed_by_space?' do

          it 'exits early on files that contain no subtitle_marks' do
            r_file = get_r_file(contents: 'text without subtitle_mark')
            v = SubtitleMarkNotFollowedBySpace.new(r_file, '_', '_', {})
            v.send(
              :no_subtitle_marks_followed_by_space?,
              r_file
            ).success.must_equal(true)
          end

        end

        describe 'find_subtitle_marks_followed_by_space' do
          [
            ["\n\n@word1\n\n@word2", []],
            ["\n\n@word1\n\nword2@ word3", [["line 5", "word2@ word3"]]],
            ["\n\n@word1\n\nword2@\u00A0word3", [["line 5", "word2@\u00A0word3"]]],
            ["\n\n@word1\n\nword2@\u202Fword3", [["line 5", "word2@\u202Fword3"]]],
            ["\n\n@word1\n\nword2@\n", []],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file
              v = SubtitleMarkNotFollowedBySpace.new(r_file, '_', '_', { })
              v.send(
                :find_subtitle_marks_followed_by_space,
                test_string
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
