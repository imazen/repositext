# encoding UTF-8
require_relative '../../../helper'

class Repositext
  class RFile
    describe 'IsBinary' do
      let(:contents) { 'binary' }
      let(:language) { Language::English.new }
      let(:filename) { '/docx_import/62/eng62-0101e_1234.docx' }
      let(:default_rfile) { RFile::Docx.new(contents, language, filename) }

      describe '#is_binary' do
        it 'returns true' do
          default_rfile.is_binary.must_equal(true)
        end
      end
    end
  end
end
