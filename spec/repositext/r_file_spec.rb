# encoding UTF-8
require_relative '../helper'

class Repositext

  describe RFile do

    let(:contents) { 'contents' }
    let(:language) { Language::English.new }
    let(:filename) { '/path/to/r_file.at' }
    let(:default_rfile) { RFile.new(contents, language, filename) }

    describe '#initialize' do

      it 'initializes contents' do
        default_rfile.contents.must_equal(contents)
      end

      it 'initializes language' do
        default_rfile.language.must_equal(language)
      end

      it 'initializes filename' do
        default_rfile.filename.must_equal(filename)
      end

    end

    describe '#basename' do

      it 'handles default data' do
        default_rfile.basename.must_equal('r_file.at')
      end

    end

    describe '#dir' do

      it 'handles default data' do
        default_rfile.dir.must_equal('/path/to')
      end

    end

    # TODO: Test all the methods which depend on repository being a real repository

  end

end
