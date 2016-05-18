class Repositext
  class RFile
    module FollowsStandardFilenameConvention

      extend ActiveSupport::Concern

      # Returns self's date_code
      def extract_date_code
        basename.match(/\d{2}-\d{4}[[:alpha:]]?/).to_s
      end

      # Extracts a 4-digit product identity id from filename
      def extract_product_identity_id
        basename.match(/(?<=_)\d{4}(?=\.)/).to_s
      end

      # Extracts a 2-digit year from filename
      def extract_year
        extract_date_code.match(/\A\d{2}/).to_s
      end

      def filename_without_dispensable_segment
        # TODO: remove dispensable part of filename
      end
    end
  end
end
