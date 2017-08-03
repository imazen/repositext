module Caracal
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
