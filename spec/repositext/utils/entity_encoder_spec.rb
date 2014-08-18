require_relative '../../helper'

describe Repositext::Utils::EntityEncoder do

  describe 'test cases' do
    [
      ["\u00A0", '&#x00A0;'],
      ["\u2011", '&#x2011;'],
      ["\u2028", '&#x2028;'],
      ["\u202F", '&#x202F;'],
      ["\uFEFF", '&#xFEFF;'],
    ].each do |input, xpect|
      it "handles #{ input.inspect }" do
        Repositext::Utils::EntityEncoder.encode(input).must_equal(xpect)
      end
    end

    [
      ["\u00AA", "\u00AA"],
    ].each do |input, xpect|
      it "doesn't handle #{ input.inspect }" do
        Repositext::Utils::EntityEncoder.encode(input).must_equal(xpect)
      end
    end
  end

end
