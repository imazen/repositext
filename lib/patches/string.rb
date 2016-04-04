class String

  # Truncates self, removing the middle portion so that the beginning and
  # end are preserved.
  # @param [Integer] max_len
  def truncate_in_the_middle(max_len)
    r = if length > max_len
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
