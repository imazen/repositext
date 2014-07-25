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
  def truncate(truncate_at, options = {})
    return dup unless length > truncate_at

    omission = options[:omission] || '…'
    length_with_room_for_omission = truncate_at - omission.length
    stop = if options[:separator]
      rindex(options[:separator], length_with_room_for_omission) || length_with_room_for_omission
    else
      length_with_room_for_omission
    end
    "#{ self[0, stop] }#{ omission }"
  end

end
