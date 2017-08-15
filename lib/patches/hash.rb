class Hash

  def merge_recursive(other)
    merge(other) do |key,old_val,new_val|
      if old_val.respond_to?(:merge_recursive) && new_val.is_a?(Hash)
        old_val.merge_recursive(new_val)
      else
        new_val
      end
    end
  end

end
