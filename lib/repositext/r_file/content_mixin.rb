class Repositext
  class RFile

    # Contains code that is specific to Content files (AT + subtitle markers)
    module ContentMixin

      extend ActiveSupport::Concern

      module ClassMethods

        # Returns a relative path to the corresponding primary file for foreign_filename
        # NOTE: This is a class method since foreign_file doesn't exist when we
        # compute this. We often only have the filename with an existing file.
        # @param foreign_filename [String]
        # @param foreign_repository [Repository]
        # @return [String]
        def relative_path_to_corresponding_primary_file(foreign_filename, foreign_repository)
          # Create a dummy foreign_file for easy access to its dir and corresponding primary filename
          dummy_foreign_file = RFile::Text.new(
            '_',
            foreign_repository.language,
            foreign_filename,
            foreign_repository
          )
          relative_path_from_to(
            dummy_foreign_file.dir,
            dummy_foreign_file.corresponding_primary_filename
          )
        end

      end

    end
  end
end
