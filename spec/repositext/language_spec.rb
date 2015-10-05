# encoding UTF-8
require_relative '../helper'

class Repositext

  describe Language do

    let(:contents) { 'contents' }
    let(:language) { Language::English.new }

    describe '.find_by_code' do

      it 'finds by 2 character language code' do
        r = Language.find_by_code(:en)
        r.class.to_s.must_equal('Repositext::Language::English')
      end

      it 'finds by 3 character language code' do
        r = Language.find_by_code(:eng)
        r.class.to_s.must_equal('Repositext::Language::English')
      end

    end

    describe '#code_2_chars' do

      it 'returns 2 character language code' do
        Language::English.new.code_2_chars.must_equal(:en)
      end

    end

    describe '#code_3_chars' do

      it 'returns 3 character language code' do
        Language::English.new.code_3_chars.must_equal(:eng)
      end

    end

    describe '#sentence_boundary_position' do
      [
        [%(word1 word2 word3), nil],
        [%(word1 word2. word3), 11],
        [%(word1 word2! word3), 11],
        [%(word1 word2? word3), 11],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          t = Language.new
          t.sentence_boundary_position(txt).must_equal(xpect)
        end
      end
    end

    describe '#name' do

      it 'returns name' do
        Language::English.new.name.must_equal('English')
      end

    end

    describe '#split_into_words' do
      [
        [%(word1 word2.), ["word1", "word2."]],
        [%(word1—word2.), ["word1", "word2."]],
      ].each do |(txt, xpect)|
        it "handles #{ txt.inspect }" do
          t = Language.new
          t.split_into_words(txt).must_equal(xpect)
        end
      end
    end

  end

end
