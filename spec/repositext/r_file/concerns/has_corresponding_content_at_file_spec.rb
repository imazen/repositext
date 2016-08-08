# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class RFile
    describe 'HasCorrespondingContentAtFile' do
      let(:contents) { 'some contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/content/62/eng62-0101e_1234.at' }
      let(:path_to_repo) { Repository::Test.create!('rt-english').first }
      let(:content_type) { ContentType.new(File.join(path_to_repo, 'ct-general')) }

      describe '#corresponding_content_at_contents' do
        # TODO
      end

      describe '#corresponding_content_at_file' do
        # TODO
      end

      describe '#corresponding_content_at_filename' do
        it 'computes default filename' do
          filename = '/docx_import/62/eng62-0101e_1234.docx'
          rfile = RFile::Docx.new(contents, language, filename, content_type)
          rfile.corresponding_content_at_filename.must_match(
            /rt\-english\/ct\-general\/content\/62\/eng62\-0101e_1234\.at\z/
          )
        end

        it 'computes default filename with multiple extensions' do
          filename = '/docx_import/62/eng62-0101e_1234.translator.pdf'
          rfile = RFile::Docx.new(contents, language, filename, content_type)
          rfile.corresponding_content_at_filename.must_match(
            /rt\-english\/ct\-general\/content\/62\/eng62\-0101e_1234\.at\z/
          )
        end
      end
    end
  end
end
