class Repositext
  class RFile
    module HasCorrespondingContentAtFile

      extend ActiveSupport::Concern

      def corresponding_content_at_contents
        corresponding_content_at_file.contents
      end

      def corresponding_content_at_file
        ccat_filename = corresponding_content_at_filename
        return nil  if !File.exists?(ccat_filename)
        RFile::Text.new(
          File.read(corresponding_content_at_filename),
          content_type.language,
          ccat_filename,
          content_type
        )
      end

      def corresponding_content_at_filename
        File.join(
          content_type.base_dir,
          'content',
          extract_year,
          [
            content_type.config_setting(:language_code_3_chars),
            extract_date_code,
            '_',
            extract_product_identity_id,
            '.at'
          ].join
        )
      end
    end
  end
end
