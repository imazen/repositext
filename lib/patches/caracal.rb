module Caracal

  class Document

    # Overrides default styles to empty list.
    # Styles are defined as part of the DOCX export.
    # Originally defined in /lib/caracal/core/styles.rb
    def self.default_styles
      []
      # Was:
      # [
      #   { id: 'Normal',   name: 'normal',    font: 'Arial',    size: 20, line: 320, color: '333333' },
      #   { id: 'Heading1', name: 'heading 1', font: 'Palatino', size: 36, bottom: 120 },
      #   { id: 'Heading2', name: 'heading 2', font: 'Arial',    size: 26, top: 120, bottom: 160, bold: true },
      #   { id: 'Heading3', name: 'heading 3', font: 'Arial',    size: 24, top: 120, bottom: 160, bold: true, italic: true, color: '666666' },
      #   { id: 'Heading4', name: 'heading 4', font: 'Palatino', size: 24, top: 120, bottom: 120, bold: true },
      #   { id: 'Heading5', name: 'heading 5', font: 'Arial',    size: 22, top: 120, bottom: 120, bold: true },
      #   { id: 'Heading6', name: 'heading 6', font: 'Arial',    size: 22, top: 120, bottom: 120, underline: true, italic: true, color: '666666' },
      #   { id: 'Title',    name: 'title',     font: 'Palatino', size: 60 },
      #   { id: 'Subtitle', name: 'subtitle',  font: 'Arial',    size: 28, top: 60 }
      # ]
    end

  end

  module Renderers

    class XmlRenderer

    private

      # This method returns a commonly used set of attributes for paragraph nodes.
      #
      def paragraph_options
        # Was: { 'w:rsidP' => '00000000', 'w:rsidRDefault' => '00000000' }.merge(run_options)
        { }.merge(run_options)
      end

      # This method returns a commonly used set of attributes for text run nodes.
      #
      def run_options
        # Was: { 'w:rsidR' => '00000000', 'w:rsidRPr' => '00000000', 'w:rsidDel' => '00000000' }
        { }
      end

    end

  end

end
