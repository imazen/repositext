class Repositext
  class Process
    class Report

      # Finds .stanza paragraphs that are not followed by .song paragraphs
      class StanzaWithoutSongParagraphs

        # Initialize a new report
        # @param content_file [RFile::Content]
        # @param kramdown_parser [Kramdown::Parser] to parse content_file contents
        def initialize(content_file, kramdown_parser)
          raise(ArgumentError.new("Invalid content_file: #{ content_file.inspect }"))  unless content_file.is_a?(RFile::Content)
          @content_file = content_file
          @kramdown_parser = kramdown_parser
        end

        # Returns a report of stanza paragraphs that are not followed by song.
        # @return [Hash]
        # Example:
        # {
        #   :filename => "/Users/johund/development/vgr-english/content/56/eng56-0603_0335.at",
        #   :stanzas_without_song => [
        #     {
        #       :line => 1328,
        #       :para_class_sequence => [
        #         "stanza: @Oh, It’s dripping with blood…",
        #         "normal: @That’s it. Raise up your hands."
        #       ]
        #     },
        #     ...
        #   ]
        # }
        def report
          # Extract series of all .stanza and .song paragraph IALs, find any
          # .stanza that are not followed by .song
          # Matches {: .stanza}
          paragraph_classes = []
          para_ial_regex = /^([^\n]+)\n\{: \.(\w+)/
          str_sc = Kramdown::Utils::StringScanner.new(@content_file.contents)
          while !str_sc.eos? do
            if str_sc.skip_until(para_ial_regex)
              paragraph_classes << {
                line: str_sc.current_line_number,
                para_class: str_sc[2],
                para_contents: str_sc[1]
              }
            else
              break
            end
          end
          stanzas_without_song = []
          paragraph_classes.each_cons(2) { |first, second|
            if 'stanza'.freeze == first[:para_class] && 'song'.freeze != second[:para_class]
              stanzas_without_song << {
                line: first[:line],
                para_class_sequence: [
                  "#{ first[:para_class] }: #{ first[:para_contents].truncate(200) }",
                  "#{ second[:para_class] }: #{ second[:para_contents].truncate(200) }",
                ]
              }
            end
          }

          Outcome.new(
            true,
            {
              filename: @content_file.filename,
              stanzas_without_song: stanzas_without_song,
            }
          )
        end

      end
    end
  end
end
