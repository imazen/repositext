require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkNoSignificantChanges do

        describe 'significant_changes?' do

          it 'expects a non-empty content_at' do
            v = SubtitleMarkNoSignificantChanges.new('_', '_', '_', {})
            lambda {
              v.send(:significant_changes?, ' ', 'subtitle_marker_csv')
            }.must_raise ArgumentError
          end

          it 'expects a non-empty subtitle_marker_csv' do
            v = SubtitleMarkNoSignificantChanges.new('_', '_', '_', {})
            lambda {
              v.send(:significant_changes?, 'content_at', ' ')
            }.must_raise ArgumentError
          end

          it "skips content_at files that don't contain subtitle_marks" do
            v = SubtitleMarkNoSignificantChanges.new('_', '_', '_', {})
            v.send(
              :significant_changes?,
              'content_at without any subtitle_marks',
              "col1\tcol2\col3\tcol4\n"
            ).success.must_equal(true)
          end

        end

        describe 'subtitle_mark_changed_significantly?' do
          [
            [1, 1, false], # no change
            [1, 2, true], # > +30%
            [24, 16, true], # < -30%
            [24, 17, false], # > -30%
            [24, 31, false], # < +30%
            [24, 32, true], # > +30%
            [25, 18, true], # < -25%
            [25, 19, false], # > -25%
            [25, 31, false], # < +25%
            [25, 32, true], # > +25%
            [60, 45, true], # < -25%
            [60, 46, false], # > -25%
            [60, 74, false], # < +25%
            [60, 75, true], # > +25%
            [61, 48, true], # < -20%
            [61, 49, false], # > -20%
            [61, 73, false], # < +20%
            [61, 74, true], # > +20%
            [120, 95, true], # < -20%
            [120, 97, false], # > -20%
            [120, 120, false], # no change
          ].each do |old_len, new_len, xpect|
            it "handles #{ [old_len, new_len] }" do
              v = SubtitleMarkNoSignificantChanges.new('_', '_', '_', {})
              v.send(
                :subtitle_mark_changed_significantly?,
                old_len, new_len
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
