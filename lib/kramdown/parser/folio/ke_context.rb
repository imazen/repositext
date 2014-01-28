# Handles workflow state and context when processing Kramdown elements
class Kramdown::Parser::Folio::KeContext

  # Initializes new kramdown::element processing context
  # @param[Hash] attrs
  #     * :root: the root kramdown element, required
  # @param[Kramdown::Parser::Folio] folio_parser instance of folio parser so that
  #     we can trigger warnings
  def initialize(attrs, folio_parser)
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
      # The kramdown root element
      'root' => Kramdown::ElementRt.new(:root, nil, nil, :encoding => 'UTF-8'),
      # The current tape_id
      'tape_id' => nil,
      # The current year_id (vgr)
      'year_id' => nil,
    }.merge(attrs)
    @folio_parser = folio_parser
  end

  # Returns value of attr_name, aises warning if attr_name returns nil
  # @param[String] attr_name
  # @param[Nokogiri::XML::Node] xn for warning location info
  def get(attr_name, xn)
    if (v = @cx[attr_name.to_s]).nil?
      @folio_parser.add_warning(xn, "#{ attr_name } is nil.")
    end
    v
  end

  # Set a ke_context attribute
  # @param[String] attr_name
  # @param[Object] attr_value
  def set(attr_name, attr_value)
    @cx[attr_name.to_s] = attr_value
  end

  # Adds an attribute to current record_mark's IAL.
  # Raises warning if record_mark is nil.
  # Also raises warning if expect_nil and attr is present.
  # @param[Nokogiri::XML::Node] xn the xn that wanted to access current record_mark
  # @param[String] attr_name
  # @param[Object] attr_value
  def set_attr_on_record_mark(xn, attr_name, attr_value, expect_nil = false)
    if @cx['record_mark'].nil?
      @folio_parser.add_warning(xn, "#{ xn.name_and_class } outside of record_mark")
      return false
    end
    if expect_nil && (existing_attr_val = !@cx['record_mark'].attr[attr_name]).nil?
      @folio_parser.add_warning(
        xn,
        "Expected record.attr[#{ attr_name }] to be nil, but was #{ existing_attr_val.inspect }"
      )
      return false
    end
    @cx['record_mark'].attr[attr_name] = attr_value
  end

  # Adds an attribute to current p's IAL. Raises warning if p is nil.
  # @param[Nokogiri::XML::Node] xn the xn that wanted to access current p
  # @param[String] attr_name
  # @param[Object] attr_value
  def set_attr_on_p(xn, attr_name, attr_value)
    if @cx['p'].nil?
      @folio_parser.add_warning(xn, 'No containing p')
      return false
    end
    @cx['p'].attr[attr_name] = attr_value
  end

  # Adds the_text to current_text_container, creating a new text
  # element if necessary
  # @param[String] the_text
  # @param[Nokogiri::XML::Node] xn for warning location
  def add_text_to_current_text_container(the_text, xn)
    if(tce = get_current_text_container(xn))
      if tce.children.last && :text == tce.children.last.type
        tce.children.last.value << the_text
      elsif '' != the_text
        tce.add_child(Kramdown::ElementRt.new(:text, the_text))
      end
    end
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
        # We already have other contents, create warning
        @folio_parser.add_warning(
          xn,
          "Inconsistent text contents of p.reference_line: #{ sanitized_content }"
        )
        # and send to deleted text
        @folio_parser.add_deleted_text(xn, sanitized_content)
      end
    end
    # increment count
    @cx['distinct_p_referenceline_contents'][sanitized_content] += 1
  end

  # Manages the text_container_stack around processing of an XML node
  # @param[Kramdown::ElementRt] new_text_container
  # @param[OpenStruct] parent_xn_context
  def with_text_container_stack(new_text_container_ke)
    @cx['text_container_stack'].push(new_text_container_ke)
    yield
  ensure
    @cx['text_container_stack'].pop
  end

  # Returns the current text container from stack
  # @param[Nokogiri::XML::Node] xn for warning location
  def get_current_text_container(xn)
    get('text_container_stack', xn).last
  end

end
