# encoding UTF-8
require_relative '../../helper'

class Repositext
  class RFile

    describe Binary do

      let(:contents) { 'some binary contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/docx_import/62/eng62-0101e_1234.docx' }
      let(:repository) {
        path_to_repo = Repository::Test.create!('rt-english').first
        Repository::Content.new(path_to_repo)
      }
      let(:default_rfile) { RFile::Binary.new(contents, language, filename, repository) }

      describe '#is_binary' do

        it 'returns true' do
          default_rfile.is_binary.must_equal(true)
        end

      end

      describe '#corresponding_content_at_filename' do

        it 'computes default filename' do
          default_rfile.corresponding_content_at_filename.must_match(
            /rt\-english\/content\/62\/eng62\-0101e_1234\.at\z/
          )
        end

      end

    end

  end
end
