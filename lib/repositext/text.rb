class Repositext

  # Represents text
  class Text

    attr_reader :contents, :language

    def initialize(contents, language)
      raise ArgumentError.new("Invalid contents: #{ contents.inspect }")  unless contents.is_a?(String)
      raise ArgumentError.new("Invalid language: #{ language.inspect }")  unless language.is_a?(Language)
      @contents = contents
      @language = language
    end

    def inspect
      %(#<#{ self.class.name }:#{ object_id } @contents=#{ contents.truncate_in_the_middle(50).inspect } @language=#{ language.inspect }>)
    end

    def length_in_chars
      @length_in_chars ||= contents.length
    end

    def length_in_words
      @length_in_words ||= words.length
    end

    def to_s
      inspect
    end

    def words
      @words ||= language.split_into_words(contents)
    end

  end
end
