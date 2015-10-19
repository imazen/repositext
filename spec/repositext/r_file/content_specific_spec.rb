# encoding UTF-8
require_relative '../../helper'

class Repositext
  class RFile
    describe 'content_specific' do

      let(:contents) { 'contents' }
      let(:language) { Language::English.new }

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
        ].each do |filename, xpect|
          it "handles #{ filename.inspect }" do
            r = RFile.new(contents, language, filename)
            r.extract_date_code.must_equal(xpect)
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
        ].each do |filename, xpect|
          it "handles #{ filename.inspect }" do
            r = RFile.new(contents, language, filename)
            r.extract_year.must_equal(xpect)
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
        ].each do |filename, xpect|
          it "handles #{ filename.inspect }" do
            r = RFile.new(contents, language, filename)
            r.extract_product_identity_id.must_equal(xpect)
          end
        end
      end

    end
  end
end
