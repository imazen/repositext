module Kramdown
  module Converter
    class Docx < Base

      class Exception < RuntimeError; end
      class InvalidElementException < Exception; end

      # Maps Kramdown block level elements to paragraph styles.
      # @return [Hash] Hash with block_level element descriptors as keys and
      # paragraph style attributes as values.
      # * id        'Heading1'  # sets the internal identifier for the style.
      # * name      'heading 1' # sets the friendly name of the style.
      # * font      'Palantino' # sets the font family.
      # * color     '333333'    # sets the text color. accepts hex RGB.
      # * size      28          # sets the font size. units in half points.
      # * bold      false       # sets the font weight.
      # * italic    false       # sets the font style.
      # * underline false       # sets whether or not to underline the text.
      # * caps      false       # sets whether or not text should be rendered in all capital letters.
      # * align     :left       # sets the alignment. accepts :left, :center, :right, and :both.
      # * line      360         # sets the line height. units in twips.
      # * top       100         # sets the spacing above the paragraph. units in twips.
      # * bottom    0           # sets the spacing below the paragraph. units in twips.
      def self.paragraph_style_mappings
        {
          'header-1' => {
            name: 'Header 1',
            id: 'header1',
            size: 28,
            bold: true,
            align: :left,
            line: 360,
            top: 100,
            bottom: 0,
          },
          'header-2' => {
            name: 'Header 2',
            id: 'header2',
            size: 24,
            bold: false,
            align: :left,
            line: 300,
            top: 80,
            bottom: 0,
          },
          'header-3' => {
            name: 'Header 3',
            id: 'header3',
            size: 20,
            bold: false,
            align: :left,
            line: 240,
            top: 60,
            bottom: 0,
          },
          'p.normal' => {
            name: 'Normal',
            id: 'normal',
            size: 12,
            align: :left,
            line: 160,
            top: 12,
            bottom: 0,
          },
          'p.test'   => {
            name: 'Paragraph Test',
            id: 'paragraphTest',
            size: 12,
            align: :left,
            line: 160,
            top: 12,
            bottom: 0,
          },
          'hr'       => {
            name: 'Horizontal rule',
            id: 'horizontalRule',
            size: 12,
            align: :left,
            line: 160,
            top: 12,
            bottom: 0,
          },
        }
      end

      # Create a DOCX converter with the given options.
      # @param root [Kramdown::Element]
      # @param options [Hash, optional]
      def initialize(root, options = {})
        super
        @options = {
          :output_file => File.new("docx_output.docx", 'w')
        }.merge(options)
        @current_document = nil # initialized in convert_root
        @current_block_el = nil # para, header, hr
        @current_run_text_contents = nil # NOTE: we assume there are no nested ems in repositext_kramdown!
      end

      # Converts el and causes side effects on @current_[document|paragraph|run]
      # @param el [Kramdown::Element]
      def convert(el)
        send(DISPATCHER[el.type], el)
      end

      # @return [String] the name of the converter method for element_type
      DISPATCHER = Hash.new {
        |h,element_type| h[element_type] = "convert_#{ element_type }"
      }

      # Converts el's child elements
      # @param el [Kramdown::Element]
      def inner(el)
        el.children.each { |child| convert(child) }
      end

    protected

      # Writes a DOCX file to disk (using @options[:output_file_name]).
      # @param el [Kramdown::Element] the kramdown root element
      # @param root [Kramdown::Element]
      # @return [? String with filename or outcome?]
      def convert_root(el)
        Caracal::Document.save(options[:output_file]) do |docx|
          @current_document = docx
          # Add style definitions
          paragraph_style_mappings.each do |_, style_attrs|
            docx.style(style_attrs)
          end
          # All convert methods are based on side effects on docx, not return values
          inner(el)
          @current_document = nil
        end
      end

      # @param el [Kramdown::Element]
      def convert_br(el)
        @current_block_el.br
      end

      # @param[Kramdown::Element] el
      def convert_em(el)
        @current_block_el.text do |run|
          @current_run_text_contents = ''
          inner(el)
          run.content = @current_run_text_contents
          # TODO: assign attrs
          @current_run_text_contents = nil
        end
      end

      def convert_entity(el)
        # TODO: decide if we want to decode entities
        add_text(Repositext::Utils::EntityEncoder.decode(el.options[:original]))
      end

      # @param el [Kramdown::Element]
      def convert_gap_mark(el)
        # Nothing to do
      end

      # @param el [Kramdown::Element]
      def convert_header(el)
        header_style_id = case el.options[:level]
        when 1 then paragraph_style_mappings['header-1'][:id]
        when 2 then paragraph_style_mappings['header-2'][:id]
        when 3 then paragraph_style_mappings['header-3'][:id]
        else
          raise InvalidElementException, "DOCX converter can't output header with levels != 1 | 2 | 3"
        end
        # TODO: wrap in italics manually?
        @current_document.p do |p|
          @current_block_el = p
          p.style(header_style_id)
          inner(el)
          @current_block_el = nil
        end
      end

      # @param[Kramdown::Element] el
      def convert_hr(el)
        # TODO: set para class
        @current_document.hr do |p|
          @current_block_el = p
          inner(el)
          @current_block_el = nil
        end
      end

      # @param el [Kramdown::Element]
      def convert_p(el)
        para_style_id = case el.attr['class']
        when 'normal' then paragraph_style_mappings['p.normal'][:id]
        when 'test' then paragraph_style_mappings['p.test'][:id]
        when NilClass then nil
        else
          raise InvalidElementException, "DOCX converter can't output p with class #{ el.attr['class'].inspect }"
        end
        @current_document.p do |p|
          @current_block_el = p
          p.style(para_style_id)  if para_style_id
          inner(el)
          @current_block_el = nil
        end
      end

      # @param el [Kramdown::Element]
      def convert_record_mark(el)
        # Nothing to do
      end

      # @param[Kramdown::Element] el
      def convert_strong(el)
        @current_block_el.text do |run|
          @current_run_text_contents = ''
          inner(el)
          run.content = @current_run_text_contents
          run.bold = true
          @current_run_text_contents = nil
        end
      end

      # @param el [Kramdown::Element]
      def convert_subtitle_mark(el)
        # TODO: Anything to do here?
      end

      # @param[Kramdown::Element] el
      def convert_text(el)
        txt = el.value.gsub(/\n/, ' ') # Remove newlines from text nodes.
        add_text(txt)
      end

      # Delegate to class method
      def paragraph_style_mappings
        self.class.paragraph_style_mappings
      end

      # @param[Kramdown::Element] el
      def convert_xml_comment(el)
        # noop
      end
      alias_method :convert_xml_pi, :convert_xml_comment
      alias_method :convert_comment, :convert_xml_comment
      alias_method :convert_blank, :convert_xml_comment

      # An exception is raised for all elements that cannot be converted by this converter.
      def method_missing(id, *args, &block)
        if id.to_s =~ /^convert_/
          raise(
            UnsupportedElementException,
            "DOCX converter can't output elements of type #{ id }"
          )
        else
          super
        end
      end

      # ----------------------------
      # :section: Helper methods for easier IDML output
      #
      # These helper methods should be used when outputting any IDML tag.
      #
      # ----------------------------


      # Creates a ParagraphStyleRange tag
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are
      # converted if +el+ is not +nil+.
      #
      # @param[Kramdown::Element] el
      # @param[String] style 'ParagraphStyle/' is automatically prepended
      # @param[Hash, optional] attrs
      def paragraph_style_range_tag(el, style, attrs = {})
        # Close any open tags that are not CharacterStyleRange or ParagraphStyleRange
        while(
          @xml_stack.last && \
          !['CharacterStyleRange', 'ParagraphStyleRange'].include?(@xml_stack.last.first)
        ) do
          emit_end_tag
        end

        attrs = attrs.merge("AppliedParagraphStyle" => "ParagraphStyle/#{ style }")

        # Try to find index of preceding ParagraphStyleRange in @xml_stack.
        prev_para_idx = @xml_stack.size - 1
        while prev_para_idx >= 0 && @xml_stack[prev_para_idx].first != 'ParagraphStyleRange' do
          prev_para_idx -= 1
        end

        if prev_para_idx == -1 || @xml_stack[prev_para_idx].last != attrs
          # No preceding ParagraphStyleRange exists, or its attrs are different
          # from current: Start new ParagraphStyleRange.
          if prev_para_idx != -1
            # Preceding ParagraphStyleRange exists, but attrs are different:
            # insert a br tag and close all open tags.
            br_tag
            (@xml_stack.size - prev_para_idx).times { emit_end_tag }
          end
          emit_start_tag('ParagraphStyleRange', attrs)
        else
          # Preceding ParagraphStyleRange exists and has identical attributes:
          # insert br tag so that we can add children to preceding ParagraphStyleRange.
          br_tag
        end

        # yield if block is given, or convert el's children into current ParagraphStyleRange
        block_given? ? yield : el && inner(el)
      end

      # Creates a CharacterStyleRange tag using #char_st_rng_tag and automatically chooses
      # the correct style for the given element.
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are
      # converted if +el+ is not +nil+.
      #
      # **Note**: Use this method rather than the #char_st_rng_tag method!
      #
      # @param[Kramdown::Element] el
      # @param[Array, optional] ancestors an array holding the ancestors of +el+.
      # @param[Proc, optional] block
      def character_style_range_tag_for_el(el, ancestors = @stack, &block)
        orig_el = el
        if ![:em, :strong].include?(el.type)
          # This is most likely a :text element: Use parent element for further processing.
          # Parent could be e.g., :p, :em, :strong
          el, ancestors = ancestors[-1], ancestors[0..-2]
        end
        if (el.type == :em && ancestors.last.type == :strong) ||
            (el.type == :strong && ancestors.last.type == :em)
          char_st_rng_tag(orig_el, 'Bold Italic', &block)
        elsif el.type == :strong
          char_st_rng_tag(orig_el, 'Bold', &block)
        elsif el.type == :em
          # We use :em to represent spans. Compute class for span:
          style = case
          when el.has_class?('bold') && el.has_class?('italic')
            # Most restrictive condition, check first
            'Bold Italic'
          when el.has_class?('bold')
            'Bold'
          when el.has_class?('italic') || '' == el.attr['class'].to_s
            'Italic'
          when el.has_class?('pn')
            'Paragraph number'
          else
            'Regular'
          end
          attr = {}
          attr['Capitalization'] = 'SmallCaps'  if el.has_class?('smcaps')
          attr['Position'] = 'Subscript'  if el.has_class?('subscript')
          attr['Position'] = 'Superscript'  if el.has_class?('superscript')
          attr['Underline'] = 'true'  if el.has_class?('underline')
          char_st_rng_tag(orig_el, style, attr, &block)
        elsif :gap_mark == el.type
          char_st_rng_tag(orig_el, nil, { 'FillColor' => "Color/GAP RED" }, &block)
        else
          char_st_rng_tag(orig_el, 'Regular', &block)
        end
      end

      # Creates a CharacterStyleRange tag
      #
      # If a block is given, it is yielded. Otherwise the children of +el+ are
      # converted if +el+ is not +nil+.
      #
      # **Note**: You should not call this method directly, but rather #character_style_range_tag_for_el instead!
      #
      # @param[Kramdown::Element] el
      # @param[String] style 'CharacterStyle/' is automatically prepended
      # @param[Hash, optional] attrs
      def char_st_rng_tag(el, style, attrs = {})
        attrs = attrs.merge("AppliedCharacterStyle" => "CharacterStyle/#{ style }")

        if @xml_stack.last.first != 'CharacterStyleRange' || @xml_stack.last.last != attrs
          # There is no preceding CharacterStyleRange, or it has different attrs.
          if @xml_stack.last.first == 'CharacterStyleRange'
            # Preceding CharacterStyleRange has different attrs: close it.
            emit_end_tag
          end
          emit_start_tag('CharacterStyleRange', attrs)
        end

        # yield if block is given, or convert el's children into current CharacterStyleRange
        block_given? ? yield : el && inner(el)
      end

      # Adds text either to @current_run_text_contents or @current_block_el
      # @param text [String]
      def add_text(text)
        if @current_run_text_contents.nil?
          # This is a text node not inside an em. Create a run.
          @current_block_el.text(text)
        else
          # We're inside a span, append contents
          @current_run_text_contents << text
        end
      end

    end

  end
end
