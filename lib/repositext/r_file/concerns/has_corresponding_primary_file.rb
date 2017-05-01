class Repositext
  class RFile
    # Include this module in any RFile subclass that has a corresponding primary file.
    module HasCorrespondingPrimaryFile

      extend ActiveSupport::Concern

      module ClassMethods
        # Returns a relative path to the corresponding primary file for foreign_filename
        # NOTE: This is a class method since foreign_file doesn't exist when we
        # compute this. We often only have the filename with an existing file.
        # @param foreign_filename [String]
        # @param foreign_content_type [ContentType]
        # @return [String]
        def relative_path_to_corresponding_primary_file(foreign_filename, foreign_content_type)
          # Create a dummy foreign_file for easy access to its dir and corresponding primary filename
          dummy_foreign_file = RFile::Content.new(
            '_',
            foreign_content_type.language,
            foreign_filename,
            foreign_content_type
          )
          relative_path_from_to(
            dummy_foreign_file.dir,
            dummy_foreign_file.corresponding_primary_filename
          )
        end
      end

      def corresponding_primary_contents
        corresponding_primary_file.contents
      end

      # NOTE: This method does not take #as_of_git_commit_attrs into consideration.
      # It always returns the current version of the file. This is because
      # it's in a different repo and this repo's git commits don't apply.
      def corresponding_primary_file
        return self  if is_primary?

        cpct = corresponding_primary_content_type
        self.class.new(
          File.read(corresponding_primary_filename),
          cpct.language,
          corresponding_primary_filename,
          cpct
        )
      end

      def corresponding_primary_filename
        return filename  if is_primary?

        primary_filename = filename.sub(
          content_type.base_dir,
          corresponding_primary_content_type.base_dir
        ).sub(
          /\/#{ content_type.config_setting(:language_code_3_chars) }/,
          "/#{ content_type.config_setting(:primary_repo_lang_code) }"
        )
      end

      # Returns true if self is a primary file
      def is_primary?
        content_type.is_primary_repo
      end
    end
  end
end
