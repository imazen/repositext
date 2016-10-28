module Kramdown
  module Converter
    # This class is identical to {Docx}, the only difference being
    # that it doesn't write the file to disc but returns the Caracal::Document
    # object.
    #
    # You can then convert that object into XML strings like so:
    # Caracal::Renderer::DocumentRenderer.render(docx)
    class DocxObject < Docx

      # @param el [Kramdown::Element]
      def convert_root(el)
        Caracal::Document.new(options[:output_file]) do |docx|
          @current_document = docx
          # All convert methods are based on side effects on docx, not return values
          inner(el)
          @current_document = nil
        end
      end

    end
  end
end
