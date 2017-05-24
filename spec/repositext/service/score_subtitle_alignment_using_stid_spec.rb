require_relative '../../helper'

class Repositext
  class Service
    class Filename
      describe ScoreSubtitleAlignmentUsingStid do

        describe 'call' do
          [
            ['1234', '1234', 10],
            ['1234', '2345', -11],
          ].each do |left_stid, right_stid, xpect|
            it "handles #{ left_stid.inspect }, #{ right_stid.inspect }" do
              ScoreSubtitleAlignmentUsingStid.call(
                left_stid: left_stid,
                right_stid: right_stid,
                default_gap_penalty: -10,
              )[:result].must_equal(xpect)
            end
          end
        end

      end
    end
  end
end
