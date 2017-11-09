class String

  # Returns contents of self as two separate strings based on self being split
  # at word boundary near the middle.
  def split_into_two
    middle = (length / 2.0).ceil
    # In order to split at a word beginning, we use rindex starting at the
    # middle of the string. This gives us trailing whitespace instead of leading:
    # ["word2 ", "word3"] instead of ["word2", " word3"].
    # NOTE: We need to handle encoded entities like "&#x8820;". They would get
    # split before the x (word boundary like so: ["&#", "x8820;"]).
    # So we only split on word boundaries that are not part of encoded entities.
    # And we match specifically on the start of encoded entities.
    word_boundary_after_middle_pos = rindex(/&#x|(?<!&#)\b(?![x\s])/, middle)
    # For strings without word boundaries (e.g., '@'), or strings that have the
    # word boundary at the beginning (e.g., 'word') we return the original
    # string and an empty string
    if word_boundary_after_middle_pos.nil? || 0 == word_boundary_after_middle_pos
      return [self.dup, '']
    end
    first = slice(0, word_boundary_after_middle_pos)
    second = slice(word_boundary_after_middle_pos, length)
    [first, second]
  end

  # Truncates self, removing the middle portion so that the beginning and
  # end are preserved.
  # @param max_len [Integer] max length of return value. If 0, nothing will be truncated
  def truncate_in_the_middle(max_len)
    r = if(max_len > 0 && length > max_len)
      half_len = max_len/2
      "#{ self[0..half_len] } [...] #{ self[-half_len..-1] }"
    else
      self
    end
    r
  end

  # Truncates self, removing the beginning of the string. It truncates on whitespace
  # only and requires a min word length for the last word.
  # @param [Integer] max_len
  # @param [Hash, optional] options
  #     * omission: the string to use for indication truncation, default: '…'
  #     * separator: where to truncate, e.g., ' ' for space
  def truncate_from_beginning(max_len, options = {})
    return dup unless length > max_len

    omission = options[:omission] || '…'
    length_with_room_for_omission = max_len - omission.length
    start = if options[:separator]
      # need to go back further to allow :separator to occur just before boundary
      s = index(options[:separator], -(length_with_room_for_omission + options[:separator].length))
      # if :separator is present and we found s, add separator length back in
      # to compensate for moving further back
      # Otherwise compute length without considering :separator
      s ? s + options[:separator].length : length - length_with_room_for_omission
    else
      length - length_with_room_for_omission
    end
    "#{ omission }#{ self[start.. -1] }"
  end

  # Returns unicode aware lower case version of self.
  # NOTE: We should make this method locale specific (using 2-letter lang code).
  # See UnicodeUtils gem for details:
  # https://github.com/lang/unicode_utils#synopsis
  def unicode_downcase
    UnicodeUtils.downcase(self)
  end

  # Returns unicode aware upper case version of self.
  # NOTE: We should make this method locale specific (using 2-letter lang code).
  # See UnicodeUtils gem for details:
  # https://github.com/lang/unicode_utils#synopsis
  def unicode_upcase
    UnicodeUtils.upcase(self)
  end

end
