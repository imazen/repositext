# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class RFile
    describe 'FollowsStandardFilenameConvention' do
      let(:contents) { 'some contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/content/62/eng62-0101e_1234.at' }
      let(:default_rfile) { RFile::Content.new(contents, language, filename) }

      describe '#extract_date_code' do
        [
          ['segment1/segment2/segment3', ''],
          ['segment1/segment2/eng71-0614_1234', '71-0614'],
          ['segment1/segment2/eng71-0614a_1234', '71-0614a'],
          ['segment1/segment2/eng71-0614_1234.at', '71-0614'],
          ['segment1/segment2/eng71-0614a_1234.at', '71-0614a'],
          ['segment1/segment2/engcab_01_-_word_1393.at', 'cab_01'],
          ['71-0614a.at', '71-0614a'],
          ['1-0614a.at', ''],
          ['71-014a.at', ''],
        ].each do |filename, xpect|
          it "handles #{ filename.inspect }" do
            r = RFile::Content.new(contents, language, filename)
            r.extract_date_code.must_equal(xpect)
          end
        end
      end

      describe '#extract_product_identity_id' do
        [
          ['segment1/segment2/segment3', true, ''],
          ['segment1/segment2/eng71-0614_1234', true, ''],
          ['segment1/segment2/eng71-0614a_1234', true, ''],
          ['segment1/segment2/eng71-0614_1234.at', true, '1234'],
          ['segment1/segment2/eng71-0614a_1234.at', true, '1234'],
          ['segment1/segment2/eng61-0614_0123.at', true, '0123'],
          ['segment1/segment2/eng61-0614_0123.at', false, '123'],
          ['segment1/segment2/engcab_01_-_word_1393.at', true, '1393'],
          ['71-0614a_1234.at', true, '1234'],
          ['1-0614a-1234.at', true, ''],
          ['71-014a_123.at', true, ''],
        ].each do |filename, include_leading_zeroes, xpect|
          it "handles #{ filename.inspect }" do
            r = RFile::Content.new(contents, language, filename)
            r.extract_product_identity_id(include_leading_zeroes).must_equal(xpect)
          end
        end
      end

      describe '#extract_year' do
        [
          ['segment1/segment2/segment3', ''],
          ['segment1/segment2/eng71-0614_1234', '71'],
          ['segment1/segment2/eng71-0614a_1234', '71'],
          ['segment1/segment2/eng71-0614_1234.at', '71'],
          ['segment1/segment2/eng71-0614a_1234.at', '71'],
          ['segment1/segment2/engcab_01_-_word_1393.at', 'cab'],
          ['71-0614a_1234.at', '71'],
          ['1-0614a_1234.at', ''],
          ['71-014a_1234.at', ''],
        ].each do |filename, xpect|
          it "handles #{ filename.inspect }" do
            r = RFile::Content.new(contents, language, filename)
            r.extract_year.must_equal(xpect)
          end
        end
      end
    end
  end
end
