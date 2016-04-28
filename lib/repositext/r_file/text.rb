class Repositext
  class RFile

    # Represents a text based file in repositext.
    class Text < RFile

      include ContentMixin
      # Specificity boundary
      include ContentAtMixin

      # Returns the corresponding primary content AT file for foreign text files
      # that are not content AT. E.g., DOCX imported at files.
      def corresponding_primary_content_at_file
        cpct = corresponding_primary_content_type
        self.class.new(
          File.read(corresponding_primary_filename),
          cpct.language,
          corresponding_primary_filename,
          cpct
        )
      end

      def corresponding_primary_contents
        corresponding_primary_file.contents
      end

      def corresponding_primary_file
        return self  if is_primary_content_type

        cpct = corresponding_primary_content_type
        self.class.new(
          File.read(corresponding_primary_filename),
          cpct.language,
          corresponding_primary_filename,
          cpct
        )
      end

      def corresponding_primary_filename
        return filename  if is_primary_content_type

        primary_filename = filename.sub(
          content_type.base_dir,
          corresponding_primary_content_type.base_dir
        ).sub(
          /\/#{ content_type.config_setting(:language_code_3_chars) }/,
          "/#{ content_type.config_setting(:primary_repo_lang_code) }"
        )
      end

      def is_binary
        false
      end

    end
  end
end
