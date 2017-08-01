module Kramdown
  module Converter
    # Converts kramdown element tree to plain text to be used for DOCX import
    # validation.
    class PlainTextForDocxImportValidation < PlainText

      # Return true to include line breaks for `.line_break` IAL classes.
      # @param options [Hash]
      def self.handle_line_break_class?(options)
        false
      end

    end
  end
end
