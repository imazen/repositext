require_relative '../../../helper'

class Repositext
  class Process
    class Fix
      describe ReplaceInvalidUnicodeLocations do
        describe '#fix' do
          [
            [
              "Nothing to replace",
              %(word word word word),
              %(word word word word),
            ],
            [
              "Default replacement",
              %(abcd),
              %(↺bcd),
            ],
          ].each do |description, test_string, xpect|
            it "handles #{ description }" do
              ReplaceInvalidUnicodeLocations.fix(test_string).result[:contents].must_equal(xpect)
            end
          end
        end
      end
    end
  end
end
