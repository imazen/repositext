# encoding UTF-8
require_relative '../../helper'

class Repositext
  class RFile

    describe Text do

      let(:contents) { 'text contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/path/to/r_file.at' }
      let(:default_rfile) { RFile::Text.new(contents, language, filename) }

      describe 'is_binary' do

        it 'returns false' do
          default_rfile.is_binary.must_equal(false)
        end

      end

    end

  end
end
