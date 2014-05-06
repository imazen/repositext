# -*- coding: utf-8 -*-
require_relative 'helper'

describe Array do

  [
    [[1,2,3], [1..3], false],
    [[1,2,3,5,6,7], [1..3, 5..7], false], # multiple ranges
    [[1,2,3,5,6,7,9], [1..3, 5..7, 9..9], false], # single item as range
    [[1,2,3,5,6,7,9], [1..3, 5..7, 9], true], # single item as item
    [['a','b','c'], ['a'..'c'], false], # characters
    [[0x2000,0x2001,0x2002], [0x2000..0x2002], false], # hex numbers
    [[3,2,1], [1..3], false], # unordered items
  ].each_with_index do |test_data, i|
    test_array, expect, replace_single_item_ranges_flag = test_data
    it "computes the correct result for example ##{ i+1 }" do
      test_array.merge_adjacent_items_into_ranges(
        replace_single_item_ranges_flag
      ).must_equal expect
    end
  end

end
