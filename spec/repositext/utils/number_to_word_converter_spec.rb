require_relative '../../helper'

class Repositext
  class Utils
    describe NumberToWordConverter do

      describe '.convert' do
        [
          [0, 'zero'],
          [10, 'ten'],
          [17, 'seventeen'],
          [173, 'one hundred and seventy three'],
          [5_347, 'five thousand three hundred and forty seven'],
          [45_347, 'forty five thousand three hundred and forty seven'],
          [245_347, 'two hundred forty five thousand three hundred and forty seven'],
          [8_245_347, 'eight million two hundred forty five thousand three hundred and forty seven'],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            NumberToWordConverter.convert(input).must_equal(xpect)
          end
        end
      end

    end
  end
end
