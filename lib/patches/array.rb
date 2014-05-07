class Array

  # Converts self to an array of items and ranges (for any adjacent items).
  # This is used to make regexes with large character classes more efficient.
  # @return[Array] a copy of self with adjacent items merged into ranges.
  #     Example: [1,2,3,5,6,9,7] => [1..3, 5..7, 9]
  def merge_adjacent_items_into_ranges(replace_single_item_ranges = false)
    array = compact.uniq.sort
    ranges = []
    if !array.empty?
      # Initialize the left and right endpoints of the range
      left, right = array.first, nil
      array.each do |item|
        # If the right endpoint is set and item is not equal to right's successor
        # then we need to create a range.
        if right && item != right.succ
          ranges << Range.new(left,right)
          left = item
        end
        right = item
      end
      ranges << Range.new(left,right)
    end
    if replace_single_item_ranges
      ranges.map { |r| r.first == r.last ? r.first : r }
    else
      ranges
    end
  end

end
