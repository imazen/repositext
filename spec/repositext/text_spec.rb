# encoding UTF-8
require_relative '../helper'

class Repositext

  describe Text do

    let(:contents) { 'contents' }
    let(:language) { Language::English.new }

    describe 'Initializing' do

      it "initializes contents" do
        t = Text.new(contents, language)
        t.contents.must_equal(contents)
      end

      it "initializes language" do
        t = Text.new(contents, language)
        t.language.must_equal(language)
      end

    end

    describe '#length_in_chars' do
      [
        [%(word1 word2 word3), 17],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          t = Text.new(txt, language)
          t.length_in_chars.must_equal(xpect)
        end
      end
    end

    describe '#length_in_words' do
      [
        [%(word1 word2 word3), 3],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          t = Text.new(txt, language)
          t.length_in_words.must_equal(xpect)
        end
      end
    end

    describe '#words' do
      [
        [%(word1 word2 word3), %w[word1 word2 word3]],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          t = Text.new(txt, language)
          t.words.must_equal(xpect)
        end
      end
    end

  end

end
