require_relative '../../helper'

describe Repositext::Fix::ConvertFolioTypographicalChars do

  [
    ['Mrs. Ford, Mrs.... I think', 'Mrs. Ford, Mrs.… I think'],
    ['-I think... I thought', '-I think… I thought']
  ].each do |(txt, xpect)|
    it "handles #{ txt.inspect }" do
      o = Repositext::Fix::ConvertFolioTypographicalChars.fix(txt)
      o.result[:contents].must_equal(xpect)
    end
  end

end
