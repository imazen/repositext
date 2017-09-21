class Repositext
  class Services

    # This service extracts a file's main title (the first level one header)
    #
    # Usage:
    #  main_title = ExtractContentAtMainTitle.call(content_at).result
    #
    class ExtractContentAtMainTitle

      # @param content_at [String]
      def self.call(content_at)
        new(content_at).call
      end

      # @param content_at [String]
      def initialize(content_at)
        @content_at = content_at
      end

      def call
        main_title_at = @content_at[/^# [^\n]+/] || ''
        main_title_plain_text = Kramdown::Document.new(main_title_at)
                                                  .to_plain_text
                                                  .strip
        Outcome.new(true, main_title_plain_text, [])
      end

    end
  end
end
