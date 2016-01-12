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
              "relativeMS\tsamples\tcharLength\tpersistentId\trecordId",
              "1\t1\t5\t\t",
              "2\t1\t5\t\t",
              "3\t1\t3\t\t",
              ''
            ].join("\n"),
          ],
          [ # with NO existing stm_csv
            "@23456@89012@456",
            nil,
            [
              "relativeMS\tsamples\tcharLength\tpersistentId\trecordId",
              "0\t0\t5\t\t",
              "0\t0\t5\t\t",
              "0\t0\t3\t\t",
              ''
            ].join("\n"),
          ],
        ].each do |content_at, existing_stm_csv, xpect|
          it "handles #{ content_at.inspect }" do
            SubtitleMarkCharacterPositions.send(
              :sync, content_at, existing_stm_csv, false
            ).result.must_equal(xpect)
          end
        end
      end

    end
  end
end
