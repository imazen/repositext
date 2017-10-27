class Repositext
  class Services

    # Returns the number of subtitle_marks in content_at
    #
    class ExtractSubtitleMarkCountContentAt

      # @param content_at [String] the text content
      # @return [Integer]
      def self.call(content_at)
        content_at.count('@')
      end

    end
  end
end
