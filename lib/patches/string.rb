class String

  # Truncates self, removing the middle portion so that the beginning and
  # end are preserved.
  # @param[Integer] max_len
  def truncate_in_the_middle(max_len)
    r = if length > max_len
      half_len = max_len/2
      "#{ self[0..half_len] } [...] #{ self[-half_len..-1] }"
    else
      self
    end
    r
  end

  # Truncates self, removing the end of the string. It truncates on whitespace
  # only and requires a min word length for the last word.
  # @param[Integer] max_len
  # @param[Hash, optional] options
  #     * omission: the string to use for indication truncation, default: '…'
  #     * separator: where to truncate, e.g., ' ' for space
  def truncate(max_len, options = {})
    return dup unless length > max_len

    omission = options[:omission] || '…'
    length_with_room_for_omission = max_len - omission.length
    stop = if options[:separator]
      rindex(options[:separator], length_with_room_for_omission) || length_with_room_for_omission
    else
      length_with_room_for_omission
    end
    "#{ self[0, stop] }#{ omission }"
  end

  # Truncates self, removing the end of the string. It truncates on whitespace
  # only and requires a min word length for the last word.
  # @param[Integer] max_len
  # @param[Hash, optional] options
  #     * omission: the string to use for indication truncation, default: '…'
  #     * separator: where to truncate, e.g., ' ' for space
  def truncate_from_beginning(max_len, options = {})
    return dup unless length > max_len

    omission = options[:omission] || '…'
    length_with_room_for_omission = max_len - omission.length
    start = if options[:separator]
      index(options[:separator], -length_with_room_for_omission) ||
      length - length_with_room_for_omission
    else
      length - length_with_room_for_omission
    end
    "#{ omission }#{ self[start.. -1] }"
  end

end
