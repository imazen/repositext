class Repositext
  class Process
    class Split
      class Subtitles

        # Represents a content file's sequence of paragraphs and sentences
        # inside each paragraph.
        class Sequence

          attr_reader :contents, :language

          def initialize(contents, language)
            raise ArgumentError.new("Invalid contents: #{ contents.inspect }")  unless contents.is_a?(String)
            raise ArgumentError.new("Invalid language: #{ language.inspect }")  unless language.is_a?(Language)
            @contents = contents
            @language = language
          end

          def paragraphs
            @paragraphs ||= split_into_paragraphs(contents, language)
          end

        private

          # Splits contents into paragraphs
          # @param contents [String] one line per paragraph, currently only used or plaintext (single newline for splitting)
          # @return [Array<Paragraph>]
          def split_into_paragraphs(contents, language)
            contents.split(/\n/).map { |paragraph_contents|
              Paragraph.new(paragraph_contents, language)
            }
          end

        end
      end
    end
  end
end
