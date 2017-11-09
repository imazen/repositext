require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkSpacing do

        describe '#subtitle_marks_spaced_correctly?' do

          it 'exits early on files that contain no subtitle_marks' do
            r_file = get_r_file(contents: 'text without subtitle_mark')
            v = SubtitleMarkSpacing.new(r_file, '_', '_', {})
            v.send(
              :subtitle_marks_spaced_correctly?,
              r_file
            ).success.must_equal(true)
          end

        end

        describe '#find_too_long_captions' do

          [
            ['text without subtitle_mark', 0],
            ['@' + ('word ' * 100), 1],
          ].each do |test_string, xpect|
            it "handles #{ test_string.inspect }" do
              r_file = get_r_file(contents: test_string)
              v = SubtitleMarkSpacing.new(r_file, '_', '_', {})
              v.send(
                :find_too_long_captions,
                test_string
              ).length.must_equal(xpect)
            end
          end

        end

      end

    end
  end
end
