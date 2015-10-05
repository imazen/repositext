class Repositext
  class Process
    class Split
      class Subtitles

        # Represents a sentence.
        class Sentence

          attr_reader :contents, :language

          # @param contents [String]
          # @param language [Language]
          def initialize(contents, language)
            raise ArgumentError.new("Invalid contents: #{ contents.inspect }")  unless contents.is_a?(String)
            raise ArgumentError.new("Invalid language: #{ language.inspect }")  unless language.is_a?(Language)
            @contents = contents
            @language = language
          end

          def content_length
            contents.length
          end

          def to_s
            %(#<#{ self.class.name }:#{ object_id } @contents=#{ contents.truncate(50) } @content_length=#{ content_length }>)
          end

        end
      end
    end
  end
end
