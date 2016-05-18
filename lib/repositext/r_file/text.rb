class Repositext
  class RFile
    # Represents a generic text file in repositext. Make sure to check more
    # specific classes before using this one!
    class Text < RFile

      def plain_text_contents
        contents
      end

    end
  end
end
