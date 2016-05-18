require_relative '../../helper'

class Repositext
  class RFile
    describe Pdf do
      let(:contents) { 'Pdf contents' }
      let(:language) { Language::English.new }
      let(:filename) { '/pdf_export/57/eng0103-1234.translator.pdf' }
      let(:default_rfile) { RFile::Pdf.new(contents, language, filename) }

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
