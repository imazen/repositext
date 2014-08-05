# -*- coding: utf-8 -*-
require_relative '../helper'

describe String do

  let(:s) { "word1 word2 word3 word4 word5 word6 word7" }

  describe '#truncate_in_the_middle' do
    [
      [[5], "wor [...] d7"],
      [[1_000], "word1 word2 word3 word4 word5 word6 word7"],
    ].each do |(args, xpect)|
      it "handles args #{ args.inspect }" do
        s.truncate_in_the_middle(*args).must_equal(xpect)
      end
    end
  end

  describe '#truncate' do
    [
      [[5], "word…"],
      [[1_000], "word1 word2 word3 word4 word5 word6 word7"],
      [[5, omission: '%%%'], "wo%%%"],
      [[20, separator: ' '], "word1 word2 word3…"],
      [[20, separator: 'x'], "word1 word2 word3 w…"],
    ].each do |(args, xpect)|
      it "handles args #{ args.inspect }" do
        s.truncate(*args).must_equal(xpect)
      end
    end
  end

  describe '#truncate_from_beginning' do
    [
      [[5], "…ord7"],
      [[1_000], "word1 word2 word3 word4 word5 word6 word7"],
      [[5, omission: '%%%'], "%%%d7"],
      [[20, separator: ' '], "… word5 word6 word7"],
      [[20, separator: 'x'], "…4 word5 word6 word7"],
    ].each do |(args, xpect)|
      it "handles args #{ args.inspect }" do
        s.truncate_from_beginning(*args).must_equal(xpect)
      end
    end
  end

end
