require_relative '../../helper'

class Repositext
  class Utils
    describe FilenamePartExtractor do

      describe '.extract_date_code' do
        [
          ['segment1/segment2/segment3', ''],
          ['segment1/segment2/eng71-0614_1234', '71-0614'],
          ['segment1/segment2/eng71-0614a_1234', '71-0614a'],
          ['segment1/segment2/eng71-0614_1234.at', '71-0614'],
          ['segment1/segment2/eng71-0614a_1234.at', '71-0614a'],
          ['71-0614a.at', '71-0614a'],
          ['1-0614a.at', ''],
          ['71-014a.at', ''],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            FilenamePartExtractor.extract_date_code(input).must_equal(xpect)
          end
        end
      end

      describe '.extract_language_code_3' do
        [
          ['segment1/segment2/segment3', ''],
          ['segment1/segment2/eng71-0614_1234', 'eng'],
          ['segment1/segment2/spn71-0614_1234', 'spn'],
          ['eng71-0614.at', 'eng'],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            FilenamePartExtractor.extract_language_code_3(input).must_equal(xpect)
          end
        end
      end

      describe '.extract_year' do
        [
          ['segment1/segment2/segment3', ''],
          ['segment1/segment2/eng71-0614_1234', '71'],
          ['segment1/segment2/eng71-0614a_1234', '71'],
          ['segment1/segment2/eng71-0614_1234.at', '71'],
          ['segment1/segment2/eng71-0614a_1234.at', '71'],
          ['71-0614a_1234.at', '71'],
          ['1-0614a_1234.at', ''],
          ['71-014a_1234.at', ''],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            FilenamePartExtractor.extract_year(input).must_equal(xpect)
          end
        end
      end

      describe '.extract_product_identity_id' do
        [
          ['segment1/segment2/segment3', ''],
          ['segment1/segment2/eng71-0614_1234', ''],
          ['segment1/segment2/eng71-0614a_1234', ''],
          ['segment1/segment2/eng71-0614_1234.at', '1234'],
          ['segment1/segment2/eng71-0614a_1234.at', '1234'],
          ['71-0614a_1234.at', '1234'],
          ['1-0614a-1234.at', ''],
          ['71-014a_123.at', ''],
        ].each do |input, xpect|
          it "handles #{ input.inspect }" do
            FilenamePartExtractor.extract_product_identity_id(input).must_equal(xpect)
          end
        end
      end

    end
  end
end
