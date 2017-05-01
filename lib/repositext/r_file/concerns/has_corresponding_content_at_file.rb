class Repositext
  class RFile
    # Include this module in any RFile subclass that has a corresponding content AT file.
    module HasCorrespondingContentAtFile

      extend ActiveSupport::Concern

      def corresponding_content_at_contents
        corresponding_content_at_file.contents
      end

      # Returns the corresponding file while considering #as_of_git_commit_attrs
      def corresponding_content_at_file
        ccat_filename = corresponding_content_at_filename
        return nil  if !File.exists?(ccat_filename)
        r = RFile::ContentAt.new(
          File.read(corresponding_content_at_filename),
          content_type.language,
          ccat_filename,
          content_type
        )
        if as_of_git_commit_attrs
          r.as_of_git_commit(*as_of_git_commit_attrs)
        else
          r
        end
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
