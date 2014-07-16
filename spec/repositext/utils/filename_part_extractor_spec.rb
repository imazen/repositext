require_relative '../../helper'

describe Repositext::Utils::FilenamePartExtractor do

  describe 'test cases' do

    [
      ['segment1/segment2/segment3', ''],
      ['segment1/segment2/eng71-0614', '71-0614'],
      ['segment1/segment2/eng71-0614a', '71-0614a'],
      ['segment1/segment2/eng71-0614.at', '71-0614'],
      ['segment1/segment2/eng71-0614a.at', '71-0614a'],
      ['71-0614a.at', '71-0614a'],
      ['1-0614a.at', ''],
      ['71-014a.at', ''],
    ].each do |input, xpect|
      it "handles #{ input.inspect }" do
        Repositext::Utils::FilenamePartExtractor.extract_date_code(input).must_equal(xpect)
      end
    end
  end

end
