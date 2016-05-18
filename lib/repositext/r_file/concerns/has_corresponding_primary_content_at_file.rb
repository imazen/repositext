class Repositext
  class RFile
    module HasCorrespondingPrimaryContentAtFile

      extend ActiveSupport::Concern

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
    end
  end
end
