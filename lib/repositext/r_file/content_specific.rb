class Repositext
  class RFile

    # Contains code that is specific to Content files (AT + subtitle markers)
    module ContentSpecific

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
          dummy_foreign_file = RFile.new(
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

        # Returns a relative path from source_path to target_path.
        # @param source_path [String] absolute path
        # @param target_path [String] absolute path
        # @return [String]
        def relative_path_from_to(source_path, target_path)
          source_pathname = Pathname.new(source_path)
          target_pathname = Pathname.new(target_path)
          target_pathname.relative_path_from(source_pathname).to_s
        end

      end

      # Returns self's date_code
      def extract_date_code
        basename.match(/\d{2}-\d{4}[[:alpha:]]?/).to_s
      end

      # Extracts a 2-digit year from filename
      def extract_year
        extract_date_code.match(/\A\d{2}/).to_s
      end

      # Extracts a 4-digit product identity id from filename
      def extract_product_identity_id
        basename.match(/(?<=_)\d{4}(?=\.)/).to_s
      end

    end
  end
end
