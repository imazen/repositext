require_relative '../../helper'

describe Repositext::Fix::NormalizeSubtitleMarkBeforeGapMarkPositions do

  [
    ['word %@ word', 'word @% word'],
    [' %@word word', '@% word word'],
    ['word @% word', 'word @% word'],
    ['%@ word', '@% word'],
    ['@% word', '@% word'],
  ].each do |(txt, xpect)|
    it "handles #{ txt.inspect }" do
      o = Repositext::Fix::NormalizeSubtitleMarkBeforeGapMarkPositions.fix(txt, '_')
      o.result[:contents].must_equal(xpect)
    end
  end

end
