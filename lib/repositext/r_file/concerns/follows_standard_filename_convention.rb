class Repositext
  class RFile
    # Include this module in any RFile subclass that follows the standard file name
    # convention of date_codes and product_identity_ids.
    module FollowsStandardFilenameConvention

      extend ActiveSupport::Concern

      module ClassMethods

        # Finds an RFile given date_code and a content_type
        # @param date_code [String]
        # @param extension [String] with leading period
        # @param content_type [ContentType]
        # @return [RFile, Nil]
        def find_by_date_code(date_code, extension, content_type)
          file_path = Dir.glob(
            File.join(
              content_type.base_dir,
              "content/**/[a-z][a-z][a-z]#{ date_code }_*#{ extension }"
            )
          ).first
          return nil  if file_path.nil?
          # create new instance of class (determined by which class this method is called on)
          new(
            File.read(file_path),
            content_type.language,
            file_path,
            content_type
          )
        end

        # Finds an RFile given product_identity_id and a content_type
        # @param product_identity_id [String]
        # @param content_type [ContentType]
        # @return [RFile, Nil]
        def find_by_product_identity_id(product_identity_id, content_type)
          file_path = Dir.glob(
            File.join(
              content_type.base_dir,
              "content/**/*_#{ product_identity_id }.*"
            )
          ).first
          return nil  if file_path.nil?
          # create new instance of class (determined by which class this method is called on)
          new(
            File.read(file_path),
            content_type.language,
            file_path,
            content_type
          )
        end

      end

      # Returns self's date_code
      def extract_date_code
        # ImplementationTag #date_code_regex
        if(m = basename.match(/(?:[a-z]{3}?)(\d{2}-\d{4}[[:alpha:]]?|[a-z]{3}_\d{2}(?=_-_))/))
          m[1]
        else
          ''
        end
      end

      # Extracts a 4-digit product identity id from filename
      def extract_product_identity_id(include_leading_zeroes = true)
        r = basename.match(/(?<=_)\d{4}(?=\.)/).to_s
        if !include_leading_zeroes
          r.sub!(/\A0+/, '')
        end
        r
      end

      # Extracts a 2-digit year or 3 letter content type identifier from filename
      def extract_year
        extract_date_code.match(/\A(\d{2}|[a-z]{3})/).to_s
      end

      def filename_without_dispensable_segment
        # TODO: remove dispensable part of filename
      end
    end
  end
end
