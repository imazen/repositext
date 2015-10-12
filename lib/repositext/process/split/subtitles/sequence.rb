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

          def as_kramdown_doc(options={})
            # NOTE: For the  use case of subtitle splitting, we assume that
            # sequences are always in plain text (vs. content AT). In that case
            # we need to convert all \n to \n\n. This is required since we feed
            # this text into kramdown tools where all paragraphs would get
            # merged into a single one as they are separated by single newlines
            # only in plain text.
            options = {
              input: 'KramdownRepositext',
              line_width: 100000, # set to very large value so that each para is on a single line
            }.merge(options)
            Kramdown::Document.new(contents.gsub(/(?<!\n)\n(?!\n)/, "\n\n"), options)
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
