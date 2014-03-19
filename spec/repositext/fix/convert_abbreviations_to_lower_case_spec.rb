require_relative '../../helper'

describe Repositext::Fix::ConvertAbbreviationsToLowerCase do

  [
    ['A.M.', '*a.m.*{: .smcaps}'],
    ['P.M.', '*p.m.*{: .smcaps}'],
    ['A.D.', '*a.d.*{: .smcaps}'],
    ['B.C.', '*b.c.*{: .smcaps}'],
    ['a.m.', 'a.m.'],
    ['p.m.', 'p.m.'],
    ['a.d.', 'a.d.'],
    ['b.c.', 'b.c.'],
    ['in A.D. 96, ', 'in *a.d.*{: .smcaps} 96, '],
    [' from A.D. 170 until ', ' from *a.d.*{: .smcaps} 170 until '],
    ["this morning about five o'clock A.M., that", "this morning about five o'clock *a.m.*{: .smcaps}, that"],
    ["says, \"Nine A.M.\" It's an ", "says, \"Nine *a.m.*{: .smcaps}\" It's an "],
    [" at five A.M. for fifty ", " at five *a.m.*{: .smcaps} for fifty "],
    [" since about three P.M. And her ", " since about three *p.m.*{: .smcaps} And her "],
    [" it’s B.C. 780. ", " it’s *b.c.*{: .smcaps} 780. "],
    ["was B.C. 538; ", "was *b.c.*{: .smcaps} 538; "],
    ["from B.C. 445", "from *b.c.*{: .smcaps} 445"],
    ["Ph.D., LL.D., double L.D., Q.S.D., A.B.C.D.E.F. on down to ", "Ph.D., LL.D., double L.D., Q.S.D., A.B.C.D.E.F. on down to "],
  ].each do |(txt, xpect)|
    it "handles #{ txt.inspect }" do
      o = Repositext::Fix::ConvertAbbreviationsToLowerCase.fix(txt)
      o.result[:contents].must_equal(xpect)
    end
  end

end
