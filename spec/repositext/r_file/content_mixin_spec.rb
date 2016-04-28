require_relative '../../helper'

class Repositext
  class RFile
    describe 'content_mixin' do

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
      let(:foreign_content_type) {
        ContentType.new(File.join(foreign_repository.base_dir, 'ct-general'))
      }

      describe '.relative_path_to_corresponding_primary_file' do
        [
          [
            'ct-general/content/15/spn15-1231_1234.at',
            '../../../../rt-english/ct-general/content/15/eng15-1231_1234.at',
          ],
        ].each do |foreign_file_repo_relative_path, xpect|
          it "handles #{ foreign_file_repo_relative_path.inspect }" do
            Text.relative_path_to_corresponding_primary_file(
              File.join(foreign_repository.base_dir, foreign_file_repo_relative_path),
              foreign_content_type
            ).must_equal(xpect)
          end
        end
      end

    end
  end
end
