require_relative '../../../helper'

class Repositext
  class Process
    class Fix
      describe AdjustSubtitleMarkPositions do

        [
          ['word@ word', 'word @word'],
          ['word@@@@ @@word', 'word @@@@@@word'],
          ["word.@” word", "word.” @word"],
          ["(@word)", "@(word)"],
          ["word.@) word", "word.) @word"],
        ].each do |(txt, xpect)|
          it "handles #{ txt.inspect }" do
            o = AdjustSubtitleMarkPositions.fix(txt, Repositext::Language::English)
            o.result.must_equal(xpect)
          end
        end

      end
    end
  end
end
