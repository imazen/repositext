class Repositext
  class RFile
    # Include this module in any RFile subclass that has a corresponding primary content AT file.
    module HasCorrespondingPrimaryContentAtFile

      extend ActiveSupport::Concern

      # Returns the corresponding primary content AT file for foreign text files
      # that are not content AT. E.g., DOCX imported at files.
      # NOTE: This method does not take #as_of_git_commit_attrs into consideration.
      # It always returns the current version of the file. This is because
      # it's in a different repo and this repo's git commits don't apply.
      def corresponding_primary_content_at_file
        cpct = corresponding_primary_content_type
        self.class.new(
          File.read(corresponding_primary_filename),
          cpct.language,
          corresponding_primary_filename,
          cpct
        )
      end
    end
  end
end
