class Repositext
  class RFile

    # Represents a binary file in repositext.
    class Binary < RFile

      include ZipArchiveMixin

      def corresponding_content_at_contents
        corresponding_content_at_file.contents
      end

      def corresponding_content_at_file
        ccat_filename = corresponding_content_at_filename
        return nil  if !File.exists?(ccat_filename)
        RFile::Text.new(
          File.read(corresponding_content_at_filename),
          repository.language,
          ccat_filename,
          repository
        )
      end

      def corresponding_content_at_filename
        File.join(
          repository.config_base_dir(:rtfile_dir),
          'content',
          extract_year,
          [
            repository.config_setting(:language_code_3_chars),
            extract_date_code,
            '_',
            extract_product_identity_id,
            '.at'
          ].join
        )
      end

      def is_binary
        true
      end

    end
  end
end
