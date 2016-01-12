# encoding UTF-8
require_relative '../helper'

class Repositext

  describe RFile do

    # TODO: Test all the methods which depend on repository being a real repository

    let(:contents) { 'contents' }
    let(:language) { Language::English.new }
    let(:filename) { '/path/to/r_file.at' }
    let(:default_rfile) { RFile.new(contents, language, filename) }

    describe '.relative_path_from_to' do
      [
        [
          '/path/to/rt-spanish/content/15/',
          '/path/to/rt-english/content/15/eng15-1231_1234.at',
          '../../../rt-english/content/15/eng15-1231_1234.at',
        ],
        [
          '/path/to/rt-spanish/content/15/',
          '/path/to/rt-english/content/15/eng15-1231_1234.subtitle_markers.csv',
          '../../../rt-english/content/15/eng15-1231_1234.subtitle_markers.csv',
        ],
      ].each do |source_path, target_path, xpect|
        it "handles #{ source_path.inspect }" do
          RFile.relative_path_from_to(
            source_path,
            target_path
          ).must_equal(xpect)
        end
      end
    end

    describe '#initialize' do

      it 'initializes contents' do
        default_rfile.contents.must_equal(contents)
      end

      it 'initializes language' do
        default_rfile.language.must_equal(language)
      end

      it 'initializes filename' do
        default_rfile.filename.must_equal(filename)
      end

    end

    describe '#basename' do

      it 'handles default data' do
        default_rfile.basename.must_equal('r_file.at')
      end

    end

    describe '#dir' do

      it 'handles default data' do
        default_rfile.dir.must_equal('/path/to')
      end

    end

    describe '#extract_date_code' do
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

    describe '#extract_product_identity_id' do
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

    describe '#extract_year' do
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

  end

end
