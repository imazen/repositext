require_relative '../../helper'

class Repositext
  class RFile
    describe Docx do
      let(:contents) { 'some binary contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/docx_import/57/eng0103-1234.docx' }
      let(:default_rfile) { RFile::Docx.new(contents, language, filename) }

      describe 'extract_zip_archive_file_contents' do
        # TODO: test with an actual ZIP archive
        it 'responds' do
          default_rfile.must_respond_to(:extract_zip_archive_file_contents)
        end
      end
    end
  end
end
