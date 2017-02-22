class Object

  # Use this method to make deep copies of e.g., nested arrays.
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end

end
