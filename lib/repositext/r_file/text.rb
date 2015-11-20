class Repositext
  class RFile

    # Represents a text based file in repositext.
    class Text < RFile

      include ContentMixin
      # specificity boundary
      include ContentAtMixin

      def corresponding_primary_contents
        corresponding_primary_file.contents
      end

      def corresponding_primary_file
        return self  if is_primary_repo

        self.class.new(
          File.read(corresponding_primary_filename),
          corresponding_primary_repository.language,
          corresponding_primary_filename,
          corresponding_primary_repository
        )
      end

      def corresponding_primary_filename
        return filename  if is_primary_repo

        primary_filename = filename.sub(
          repository.config_base_dir(:rtfile_dir),
          corresponding_primary_repo_base_dir
        ).sub(
          /\/#{ repository.config_setting(:language_code_3_chars) }/,
          "/#{ repository.config_setting(:primary_repo_lang_code) }"
        )
      end

      def is_binary
        false
      end

    end
  end
end
