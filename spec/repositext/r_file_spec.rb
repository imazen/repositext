# encoding UTF-8
require_relative '../helper'

class Repositext

  describe RFile do

    let(:contents) { 'contents' }
    let(:language) { Language::English.new }
    let(:filename) { '/path/to/r_file.at' }

    describe '#initialize' do

      it 'initializes contents' do
        r = RFile.new(contents, language, filename)
        r.contents.must_equal(contents)
      end

      it 'initializes language' do
        r = RFile.new(contents, language, filename)
        r.language.must_equal(language)
      end

      it 'initializes filename' do
        r = RFile.new(contents, language, filename)
        r.filename.must_equal(filename)
      end

    end

    # TODO: Test all the methods which depend on repository being a real repository

  end

end
