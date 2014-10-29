class Repositext
  class Utils
    # Extracts parts from filenames
    class FilenamePartExtractor

      # Extracts the date code from a filename
      #
      # /eng47-0412_0002.at => '47-0412'
      # or
      # /eng47-0412_0002b.at => '47-0412b'
      #
      # @param[String] filename the filename. With or without path
      # @return[String] the corresponding date code
      def self.extract_date_code(filename)
        basename = filename.split('/').last
        basename.match(/\d{2}-\d{4}[[:alpha:]]?/).to_s
      end

      # Extracts a 2-digit year from filename
      def self.extract_year(filename)
        extract_date_code(filename).match(/\A\d{2}/).to_s
      end

      # Extracts a 4-digit product identity id from filename
      def self.extract_product_identity_id(filename)
        basename = filename.split('/').last
        basename.match(/(?<=_)\d{4}(?=\.)/).to_s
      end

    end
  end
end
