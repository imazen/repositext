# Handles workflow state and context when processing Kramdown elements
class Kramdown::Parser::Folio::KeContext

  include ::Kramdown::KeContextMixin

  # Initializes new kramdown::element processing context
  # @param[Hash] attrs
  #     * 'root': the root kramdown element, required
  # @param[Kramdown::Parser::Folio] parser instance of folio parser so that
  #     we can trigger warnings
  def initialize(attrs, parser)
    @cx = {
      # Stack of Kramdown elements into which to insert text content. Can be [p, span, header].
      # Update stack around calls to process_xml_node.
      'text_container_stack' => [],
      # Collect distinct text contents of p.reference_line, then when processing
      # each node, check against distinct and warn if different. Record number
      # of occurrences with each distinct value so that we can identify the
      # exceptions vs. the rule.
      'distinct_p_referenceline_contents' => Hash.new(0),
      # The current p element
      'p' => nil,
      # The current record_id (vgr)
      'record_id' => nil,
      # The current record_mark
      'record_mark' => nil,
      # The current tape_id
      'tape_id' => nil,
      # The current year_id (vgr)
      'year_id' => nil,
    }.merge(attrs)
    @parser = parser
  end

  def inspect
    @cx.keys.inject({}) { |m,k|
      m[k] = case k
      when "text_container_stack"
        @cx[k].inspect
      when "distinct_p_referenceline_contents"
        "#{ (@cx[k] || []).size } items"
      when "p"
        @cx[k].element_summary
      when "record_id"
        @cx[k].inspect
      when "record_mark"
        @cx[k].element_summary
      when "root"
        @cx[k].element_summary
      when "tape_id"
        @cx[k].inspect
      when "year_id"
        @cx[k].inspect
      else
        raise "handle this: #{ k.inspect }"
      end
      m
    }.inspect
  end

  # Records distinct contents and adds a warning if they are inconsistent with
  # existing ones.
  # @param[String] content
  # @param[Nokogiri::XML::Node] xn for warning location
  def record_distinct_reference_line_contents(content, xn)
    # Sanitize content
    sanitized_content = content.strip.split(/[\s]+/).map { |e| # split on spaces, newlines and tabs
      e.gsub(/\d{8}/, '') # remove unique record ids before checking distinctness
    }.map { |e|
      '' == e.strip ? nil : e.strip # remove blank elements
    }.compact.join(', ')
    if 0 == @cx['distinct_p_referenceline_contents'][sanitized_content]
      # First occurrence of this distinct content
      if @cx['distinct_p_referenceline_contents'].keys.any?
        # We already have other contents. We used to raise a warning,
        # however we anticipate differences, so we're not adding warnings.
        # @parser.add_warning(
        #   xn,
        #   [
        #     "Inconsistent text contents of p.reference_line:",
        #     "sanitized_content:",
        #     sanitized_content.inspect,
        #     "existing referenceline_contents:",
        #     @cx['distinct_p_referenceline_contents'].inspect
        #   ].join(' ')
        # )
        # and send to deleted text
        @parser.add_deleted_text(xn, sanitized_content)
      end
    end
    # increment count
    @cx['distinct_p_referenceline_contents'][sanitized_content] += 1
  end

  # Adds an attribute to current record_mark's IAL.
  # Raises warning if record_mark is nil.
  # Also raises warning if expect_nil and attr is present.
  # @param[Nokogiri::XML::Node] xn the xn that wanted to access current record_mark
  # @param[String] attr_name
  # @param[Object] attr_value
  def set_attr_on_record_mark(xn, attr_name, attr_value, expect_nil = false)
    if @cx['record_mark'].nil?
      @parser.add_warning(xn, "#{ xn.name_and_class } outside of record_mark")
      return false
    end
    if expect_nil && (existing_attr_val = !@cx['record_mark'].attr[attr_name]).nil?
      @parser.add_warning(
        xn,
        "Expected record.attr[#{ attr_name }] to be nil, but was #{ existing_attr_val.inspect }"
      )
      return false
    end
    @cx['record_mark'].attr[attr_name] = attr_value
  end

end
