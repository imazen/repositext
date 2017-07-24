class Repositext
  class Services

    # This service provides text extraction from DOCX files.
    #
    # Usage:
    #  outcome = ExtractTextFromPdf.call(docx_filename)
    #  plain_text = outcome.result
    #
    class ExtractTextFromDocx

      def self.call(docx_filename)
        new(docx_filename).call
      end

      # @param port [Integer, optional] the TCP port the server listens to
      def initialize(docx_filename)
        @docx_filename = docx_filename
      end

      def call
        cmd = [
          "unzip -p",
          @docx_filename,
          "word/document.xml",
        ].join(' ')
        document_xml, std_error, status = Open3.capture3(cmd)
        if 0 == status
          # Insert paragraph boundary markers so that we can insert newlines at those locations
          prepared_document_xml = document_xml.gsub(/(<\/w:p>)/, '===para_boundary===\1')
          # Use Nokogiri's inner text method
          plain_text = Nokogiri.XML(prepared_document_xml).text
          # Insert spaces after paragraph numbers, replace paragraph boundaries
          # with double newlines, and normalize trailing newline.
          sanitized_plain_text = plain_text.gsub(/\s{0,3}===para_boundary===(\d+[a-z]?)\s*/, "\n\n" + '\1 ')
                                           .gsub(/\s{0,3}===para_boundary===/, "\n\n")
                                           .sub(/\n*\z/, "\n")
          Outcome.new(true, sanitized_plain_text, [])
        else
          Outcome.new(false, nil, ["Error code: #{ status }", std_error])
        end
      end

    end
  end
end
