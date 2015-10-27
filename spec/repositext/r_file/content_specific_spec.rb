# encoding UTF-8
require_relative '../../helper'

class Repositext
  class RFile
    describe 'content_specific' do

      let(:contents) { 'contents' }
      let(:language) { Language::English.new }
      let(:foreign_language) { Language::Spanish.new }
      let(:primary_repository) {
        path_to_repo = Repository::Test.create!('rt-english').first
        Repository::Content.new(path_to_repo)
      }
      let(:foreign_repository) {
        path_to_repo = Repository::Test.create!('rt-spanish').first
        Repository::Content.new(path_to_repo)
      }

      describe '.relative_path_to_corresponding_primary_file' do
        [
          [
            '/content/15/spn15-1231_1234.at',
            '../../../rt-english/content/15/eng15-1231_1234.at',
          ],
        ].each do |foreign_file_repo_relative_path, xpect|
          it "handles #{ foreign_file_repo_relative_path.inspect }" do
            RFile.relative_path_to_corresponding_primary_file(
              File.join(foreign_repository.base_dir, foreign_file_repo_relative_path),
              foreign_repository
            ).must_equal(xpect)
          end
        end
      end

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

    end
  end
end
