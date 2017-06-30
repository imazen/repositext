# -*- coding: utf-8 -*-
require_relative '../helper'

describe Array do

  describe '#merge_adjacent_items_into_ranges' do
    [
      [[1,2,3], [1..3], false],
      [[1,2,3,5,6,7], [1..3, 5..7], false], # multiple ranges
      [[1,2,3,5,6,7,9], [1..3, 5..7, 9..9], false], # single item as range
      [[1,2,3,5,6,7,9], [1..3, 5..7, 9], true], # single item as item
      [['a','b','c'], ['a'..'c'], false], # characters
      [[0x2000,0x2001,0x2002], [0x2000..0x2002], false], # hex numbers
      [[3,2,1], [1..3], false], # unordered items
    ].each do |test_data|
      test_array, expect, replace_single_item_ranges_flag = test_data
      it "handles #{ test_data.inspect }" do
        test_array.merge_adjacent_items_into_ranges(
          replace_single_item_ranges_flag
        ).must_equal expect
      end
    end
  end

  describe '#mean' do
    [
      [[1,2,3], 2],
      [[1,2,3,5,6,7], 4],
    ].each do |(test_data, xpect)|
      it "handles #{ test_data.inspect }" do
        test_data.mean.must_equal(xpect)
      end
    end

    it 'handles empty array' do
      [].mean.must_be_nil
    end
  end

  describe '#median' do
    [
      [[1,2,3], 2],
      [[1,2,3,5,6,7], 4],
    ].each do |(test_data, xpect)|
      it "handles #{ test_data.inspect }" do
        test_data.median.must_equal(xpect)
      end
    end

    it 'handles empty array' do
      [].median.must_be_nil
    end
  end

end
