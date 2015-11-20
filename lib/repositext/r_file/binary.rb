class Repositext
  class RFile

    # Represents a binary file in repositext.
    class Binary < RFile

      include ZipArchiveMixin

      def is_binary
        true
      end

    end
  end
end
