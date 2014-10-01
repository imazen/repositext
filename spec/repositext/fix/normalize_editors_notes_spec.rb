require_relative '../../helper'

class Repositext
  class Fix
    describe NormalizeEditorsNotes do

      [
        ['word word--*Ed.]', 'word word*—Ed.]'],
        ['word—*—Ed.]', 'word*—Ed.]'],
        ['*word word word—*—Ed.]', '*word word word*—Ed.]'],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          o = NormalizeEditorsNotes.fix(txt, '_')
          o.result[:contents].must_equal(xpect)
        end
      end

    end
  end
end
