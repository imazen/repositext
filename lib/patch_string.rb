class String

  # Truncates a string, removing the middle portion so that the beginning and
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

end
