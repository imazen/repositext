# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class RFile
    describe 'HasCorrespondingPrimaryFile' do
      let(:contents) { 'contents' }
      let(:primary_language) { Language::English.new }
      let(:foreign_language) { Language::Spanish.new }
      let(:content_type_name) { 'general' }
      let(:primary_repo_name) { 'rt-english' }
      let(:path_to_primary_repo) {
        File.join(Repository::Test.repos_folder, primary_repo_name, '')
      }
      let(:primary_repo) {
        Repository::Test.create!(primary_repo_name)
        Repository::Content.new(path_to_primary_repo)
      }
      let(:path_to_primary_content_type) {
        File.join(primary_repo.base_dir, "ct-#{ content_type_name }", '')
      }
      let(:primary_content_type) {
        ContentType.new(path_to_primary_content_type)
      }
      let(:foreign_repo_name) { 'rt-spanish' }
      let(:path_to_foreign_repo) {
        File.join(Repository::Test.repos_folder, foreign_repo_name, '')
      }
      let(:foreign_repo) {
        Repository::Test.create!(foreign_repo_name)
        Repository::Content.new(path_to_foreign_repo)
      }
      let(:path_to_foreign_content_type) {
        File.join(foreign_repo.base_dir, "ct-#{ content_type_name }", '')
      }
      let(:foreign_content_type) {
        ContentType.new(path_to_foreign_content_type)
      }
      let(:primary_filename) {
        File.join(path_to_primary_content_type, "content/57/eng57-0103-1234.txt")
      }
      let(:foreign_filename) {
        File.join(path_to_foreign_content_type, "content/57/spn57-0103-1234.txt")
      }
      let(:primary_rfile) {
        RFile::Content.new(contents, primary_language, primary_filename, primary_content_type)
      }
      let(:foreign_rfile) {
        RFile::Content.new(contents, foreign_language, foreign_filename, foreign_content_type)
      }

      describe '.relative_path_to_corresponding_primary_file' do
        [
          [
            'ct-general/content/15/spn15-1231_1234.at',
            '../../../../rt-english/ct-general/content/15/eng15-1231_1234.at',
          ],
        ].each do |foreign_file_repo_relative_path, xpect|
          it "handles #{ foreign_file_repo_relative_path.inspect }" do
            RFile::Content.relative_path_to_corresponding_primary_file(
              File.join(foreign_repo.base_dir, foreign_file_repo_relative_path),
              foreign_content_type
            ).must_equal(xpect)
          end
        end
      end

      describe '.corresponding_primary_contents' do
        # TODO
      end

      describe '.corresponding_primary_file' do
        # TODO
      end

      describe '.corresponding_primary_filename' do
        it 'handles the default case for primary' do
          primary_rfile.corresponding_primary_filename.must_equal(
            primary_filename
          )
        end

        it 'handles the default case for foreign' do
          foreign_rfile.corresponding_primary_filename.must_equal(
            primary_filename
          )
        end
      end
    end
  end
end
