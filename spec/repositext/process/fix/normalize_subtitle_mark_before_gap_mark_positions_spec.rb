require_relative '../../../helper'

class Repositext
  class Process
    class Fix
      describe NormalizeSubtitleMarkBeforeGapMarkPositions do

        [
          ['word %@ word', 'word @% word'],
          [' %@word word', '@% word word'],
          ['word @% word', 'word @% word'],
          ['%@ word', '@% word'],
          ['@% word', '@% word'],
          [' %@@@word', '@% @@word'],
          [' @@@%word', '@% @@word'],
          [' %word', '% word'],
          [' @word', '@ word'],
          [' @@@@@word', '@ @@@@word'],
          ['@% @@word', '@% @@word'],
        ].each do |(txt, xpect)|
          it "handles #{ txt.inspect }" do
            o = NormalizeSubtitleMarkBeforeGapMarkPositions.fix(txt, '_')
            o.result[:contents].must_equal(xpect)
          end
        end

      end
    end
  end
end
