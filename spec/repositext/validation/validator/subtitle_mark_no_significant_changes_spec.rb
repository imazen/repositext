require_relative '../../../helper'

class Repositext
  class Validation
    class Validator

      describe SubtitleMarkNoSignificantChanges do

        describe 'significant_changes?' do
          # NOTE: This is an integration method, not testing it
        end

        describe 'subtitle_mark_changed_significantly?' do
          [
            [1, 1, 1, 1, false],
            [1, 24, 8, 24, false],
            [1, 24, 9, 24, true],
            [1, 25, 7, 25, false],
            [1, 25, 8, 25, true],
            [1, 60, 15, 60, false],
            [1, 60, 16, 60, true],
            [1, 61, 13, 61, false],
            [1, 61, 14, 61, true],
            [1, 120, 24, 120, false],
            [1, 120, 25, 120, true],
          ].each do |old_pos, old_len, new_pos, new_len, xpect|
            it "handles #{ [old_pos, old_len, new_pos, new_len] }" do
              v = Validator::SubtitleMarkNoSignificantChanges.new(
                '_',
                '_',
                '_',
                {}
              )
              v.send(
                :subtitle_mark_changed_significantly?,
                old_pos, old_len, new_pos, new_len
              ).must_equal(xpect)
            end
          end
        end

      end

    end
  end
end
