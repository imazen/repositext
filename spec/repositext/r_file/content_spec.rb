require_relative '../../helper'

class Repositext
  class RFile
    describe Content do
      let(:contents) { 'some contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/content/57/eng0103-1234.txt' }
      let(:default_rfile) { RFile::Content.new(contents, language, filename) }

      # This class only includes mixins, so we're just testing one method
      # to make sure the class loads.
      describe 'filename' do
        it 'responds' do
          default_rfile.must_respond_to(:filename)
        end
      end
    end
  end
end
