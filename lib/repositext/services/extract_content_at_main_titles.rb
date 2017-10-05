class Repositext
  class Services

    # This service extracts a file's main titles: The first level 1 header by
    # default, and the first level 2 header if requested.
    #
    # Usage:
    #  main_title = ExtractContentAtMainTitles.call(content_at, :content_at).result
    #
    class ExtractContentAtMainTitles

      # @param content_at [String]
      # @param format [Symbol] one of :content_at or :plain_text
      def self.call(content_at, format=:content_at, include_level_2_title=false)
        new(content_at, format, include_level_2_title).call
      end

      # @param content_at [String]
      def initialize(content_at, format, include_level_2_title)
        @content_at = content_at
        @format = format
        @include_level_2_title = include_level_2_title
      end

      # @return [String, Array<String>] Either just level 1 header, or array
      # of level 1 and level 2 headers.
      def call
        level_1_title = @content_at[/^# [^\n]+/] || ''
        level_2_title = @content_at[/^## [^\n]+/] || ''
        r = case @format
        when :content_at
          [level_1_title, level_2_title].map { |e| e.sub(/^#+ /, '') }
        when :plain_text
          [level_1_title, level_2_title].map { |e|
            Kramdown::Document.new(e).to_plain_text.strip
          }
        else
          raise "Handle this: #{ @format.inspect }"
        end
        if @include_level_2_title
          Outcome.new(true, r, [])
        else
          Outcome.new(true, r.first, [])
        end
      end

    end
  end
end
