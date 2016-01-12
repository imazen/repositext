require_relative '../../helper'

class Repositext
  class RFile
    describe ZipArchiveMixin do

      let(:contents) { 'some binary contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/path/to/r_file.at' }
      let(:default_rfile) { RFile::Binary.new(contents, language, filename) }

      describe 'extract_zip_archive_file_contents' do

        # TODO: test with an actual ZIP archive

        it 'responds' do
          default_rfile.must_respond_to(:extract_zip_archive_file_contents)
        end

      end

    end

  end
end
