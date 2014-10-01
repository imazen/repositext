require_relative '../../helper'

class Repositext
  class Utils
    describe EntityEncoder do

      describe '#encode' do
        [
          ["\u00A0", '&#x00A0;'],
          ["\u2011", '&#x2011;'],
          ["\u2028", '&#x2028;'],
          ["\u202F", '&#x202F;'],
          ["\uFEFF", '&#xFEFF;'],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            EntityEncoder.encode(input).must_equal(xpect)
          end
        end

        [
          ["\u00AA", "\u00AA"],
        ].each do |input, xpect|
          it "doesn't handle #{ input.inspect }" do
            EntityEncoder.encode(input).must_equal(xpect)
          end
        end
      end

      describe '#decode' do
        [
          ['&#x00A0;', "\u00A0"],
          ['&#x2011;', "\u2011"],
          ['&#x2028;', "\u2028"],
          ['&#x202F;', "\u202F"],
          ['&#xFEFF;', "\uFEFF"],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            EntityEncoder.decode(input).must_equal(xpect)
          end
        end

        [
          ["&#x00AA;", "&#x00AA;"],
        ].each do |input, xpect|
          it "doesn't handle #{ input.inspect }" do
            EntityEncoder.encode(input).must_equal(xpect)
          end
        end
      end

    end
  end
end
