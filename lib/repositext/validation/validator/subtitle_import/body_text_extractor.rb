# -*- coding: utf-8 -*-
class Repositext
  class Validation
    class Validator
      module BodyTextExtractor

        # Returns just the body text of import_file_contents. Strips title
        # and id_title and id_paragraph and all tokens but :subtitle_mark
        # @param[String] import_file_contents
        def extract_body_text_with_subtitle_marks(import_file_contents)
          content = import_file_contents.dup
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

      end
    end
  end
end
