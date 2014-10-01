require_relative '../../helper'

class Repositext
  class Sync
    describe SubtitleMarkCharacterPositions do

      describe 'sync' do
        [
          [ # with existing stm_csv
            "@23456@89012@456",
            [
              "relativeMS\tsamples",
              "1\t1",
              "2\t1",
              "3\t1",
            ].join("\n"),
            [
              "relativeMS\tsamples\tcharPos\tcharLength",
              "1\t1\t1\t5",
              "2\t1\t7\t5",
              "3\t1\t13\t3",
              ''
            ].join("\n"),
          ],
          [ # with NO existing stm_csv
            "@23456@89012@456",
            nil,
            [
              "relativeMS\tsamples\tcharPos\tcharLength",
              "\t\t1\t5",
              "\t\t7\t5",
              "\t\t13\t3",
              ''
            ].join("\n"),
          ],
        ].each do |content_at, existing_stm_csv, xpect|
          it "handles #{ content_at.inspect }" do
            SubtitleMarkCharacterPositions.send(
              :sync, content_at, existing_stm_csv
            ).result.must_equal(xpect)
          end
        end
      end

    end
  end
end
