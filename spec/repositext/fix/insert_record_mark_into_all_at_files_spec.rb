require_relative '../../helper'

class Repositext
  class Fix
    describe InsertRecordMarkIntoAllAtFiles do

      describe '.contains_no_record_marks?' do

        [
          [%(^^^ {: .rid #rid-58660019 kpn="001"}\n\nword %word word word word \n\n), false],
          [%(\n^^^ {: .rid #rid-58660019 kpn="001"}\n\nword %word word word word \n\n), false],
          [%(word\n\n), true],
          [%(^^), true],
          [%(word ^^^ word), true],
        ].each do |(txt, xpect)|
          it "handles #{ txt.inspect }" do
            InsertRecordMarkIntoAllAtFiles.contains_no_record_marks?(txt).must_equal(xpect)
          end
        end

      end
    end
  end
end
