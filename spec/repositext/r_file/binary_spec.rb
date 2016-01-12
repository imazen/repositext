# encoding UTF-8
require_relative '../../helper'

class Repositext
  class RFile

    describe Binary do

      let(:contents) { 'some binary contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/path/to/r_file.at' }
      let(:default_rfile) { RFile::Binary.new(contents, language, filename) }

      describe '#is_binary' do

        it 'returns true' do
          default_rfile.is_binary.must_equal(true)
        end

      end

    end

  end
end
