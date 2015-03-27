class Repositext
  class Utils
    class SubtitleMarkTools

      # Returns array with headers for subtitle_markers CSV file
      def self.csv_headers
        ['relativeMS', 'samples', 'charPos', 'charLength']
      end

      # Returns just the body text of txt. Strips id_title and id_paragraph and
      # all tokens except :subtitle_mark. Preserves line number consistency. In other
      # words, if a text fragment was on line 17 before being processed here,
      # it would still be on line 17 after processing.
      # @param[String] txt
      def self.extract_body_text_with_subtitle_marks_only(txt)
        # Remove id title and paragraph
        content = Repositext::Utils::IdPageRemover.remove(txt)

        # Replace certain block elements with spaces. This is necessary to
        # preserve line number consistency. Suspension::TokenRemover would
        # remove the block's entire line, introducing errors in line numbers for
        # subsequent lines.
        content_without_blocks = content.gsub(/^\{:[^\n]+(?=\n)/, '') # block_ials
                                        .gsub(/^\^\^\^[^\n]+(?=\n)/, '') # record_marks
        # Remove all tokens but :subtitle_mark from content_at
        content_with_subtitle_marks_only = Suspension::TokenRemover.new(
          content_without_blocks,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :subtitle_mark != e.name }
        ).remove
      end

      # Returns an array of Hashes that describe each caption in txt
      # @param txt [String] typically content_at
      # @param txt_is_already_cleaned_up [Boolean] set to true if txt has already
      #   been processed through extract_body_text_with_subtitle_marks_only
      # @return[Array<Hash>] with the following keys for each caption:
      #   :char_pos
      #   :char_length
      #   :line
      #   :excerpt
      def self.extract_captions(txt, txt_is_already_cleaned_up=false)
        content = txt.dup
        if !txt_is_already_cleaned_up
          content = extract_body_text_with_subtitle_marks_only(content)
        end

        captions = []
        current_char_pos = 1
        line_count = 1
        content.split('@').each_with_index { |caption, idx|
          if 0 == idx
            # handle text before the first subtitle_mark (Not a caption!)
            current_char_pos += caption.length
            line_count += caption.count("\n")
            next
          end
          # Remove leading and trailing whitespace from caption when determining its length
          captions << {
            char_pos: current_char_pos,
            char_length: caption.strip.length,
            line: line_count,
            excerpt: "@#{ caption.truncate(40) }"
          }
          # update current_char_pos, add 1 for removed subtitle_mark (split)
          current_char_pos += (1 + caption.length)
          line_count += caption.count("\n")
        }
        captions
      end

    end
  end
end
