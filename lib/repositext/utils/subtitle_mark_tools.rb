class Repositext
  class Utils
    class SubtitleMarkTools

      # Returns array with headers for subtitle_markers CSV file
      def self.csv_headers
        ['relativeMS', 'samples', 'charPos', 'charLength']
      end

      # Returns just the body text of txt. Strips title
      # and id_title and id_paragraph and all tokens but :subtitle_mark
      # @param[String] txt
      def self.extract_body_text_with_subtitle_marks_only(txt)
        content = txt.dup
        # Remove title
        content.gsub!(/^#[^\n]+\n/, '')
        # Remove id title and paragraph
        content.gsub!(
          /
            [^\n]+\n # the line before a line that contains '.id_title1'
            [^\n]+\.id_title1 # line that contains id_title
            .* # anything after the line that contains .id_title
          /mx, # multiline so that the last .* matches multiple lines to the end of file
          ''
        )

        # Remove all tokens but :subtitle_mark from content_at
        content_with_subtitle_marks_only = Suspension::TokenRemover.new(
          content,
          Suspension::REPOSITEXT_TOKENS.find_all { |e| :subtitle_mark != e.name }
        ).remove
      end

      # Returns an array of Hashes that describe each caption in txt
      # @param[String] txt, typically content_at
      # @param[Boolean] txt_is_already_cleaned_up set to true if txt has already
      #   been processed through extract_body_text_with_subtitle_marks_only
      # @return[Array<Hash>] with the following keys for each caption:
      #   :char_pos
      #   :char_length
      #   :excerpt
      def self.extract_captions(txt, txt_is_already_cleaned_up=false)
        content = txt.dup
        if !txt_is_already_cleaned_up
          content = extract_body_text_with_subtitle_marks_only(content)
        end

        captions = []
        current_char_pos = 1
        content.split('@').each_with_index { |caption, idx|
          if 0 == idx
            # handle text before the first subtitle_mark (Not a caption!)
            current_char_pos += caption.length
            next
          end
          # Remove leading and trailing whitespace from caption when determining its length
          captions << {
            :char_pos => current_char_pos,
            :char_length => caption.strip.length,
            :excerpt => "@#{ caption.truncate(40) }"
          }
          # update current_char_pos, add 1 for removed subtitle_mark (split)
          current_char_pos += (1 + caption.length)
        }
        captions
      end

    end
  end
end
