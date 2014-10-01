require_relative '../../helper'

class Repositext
  class Fix
    describe RemoveUnderscoresInsideFolioParagraphNumbers do

      [
        ['*14\_*{: .pn}', '*14*{: .pn}'],
        ['*14*{: .pn}', '*14*{: .pn}'],
        ['*14 *{: .pn}', '*14 *{: .pn}'],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          o = RemoveUnderscoresInsideFolioParagraphNumbers.fix(txt, '_')
          o.result[:contents].must_equal(xpect)
        end
      end

    end
  end
end
