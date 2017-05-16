class Repositext
  class RFile
    # Represents a generic JSON file in repositext. Make sure to check more
    # specific classes before using this one!
    class Json < RFile

      # Returns all key value pairs as hash
      def get_all_attributes
        JSON.parse(contents)
      end

    end
  end
end
