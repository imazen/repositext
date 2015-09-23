# Handles workflow state and context when processing Kramdown elements
class Kramdown::Parser::Docx::KeContext

  include ::Kramdown::KeContextMixin

  # Initializes new kramdown::element processing context
  # @param attrs [Hash]
  #     * 'root': the root kramdown element, required
  # @param parser [Kramdown::Parser] instance of kramdown parser so that
  #     we can trigger warnings
  def initialize(attrs, parser)
    @cx = {
      # Stack of Kramdown elements into which to insert text content. Can be [p, span, header].
      # Update stack around calls to process_xml_node.
      'text_container_stack' => [],
      # The current p element
      'p' => nil,
    }.merge(attrs)
    @parser = parser
  end

  def inspect
    @cx.keys.inject({}) { |m,k|
      m[k] = case k
      when "text_container_stack"
        @cx[k].inspect
      when "p"
        @cx[k].element_summary
      when "root"
        @cx[k].element_summary
      else
        raise "handle this: #{ k.inspect }"
      end
      m
    }.inspect
  end

end
