module Kramdown
  module Converter
    # Converts kramdown element tree to Docx file saved to options[:output_file].
    #
    # Naming conventions
    #
    # * node: refers to a Caracal node (DOCX/XML space).
    # * element: refers to a Kramdown::Element (kramdown space).
    # * ke: l_var that refers to a kramdown element
    # * xn: l_var that refers to an XML node
    #
    # How to handle nested spans
    #
    # Nested spans in kramdown AT need to be converted into sequences of text
    # runs since docx does not allow for nested runs.
    #
    # Example:
    #
    #     word1 **word2 *word3* word4** word5
    #
    # gets converted to
    #
    #     <w:p>
    #       <w:r>
    #         <w:t>word1 <w:t>
    #       </w:r>
    #       <w:r>
    #         <w:rPr [bold]>
    #         <w:t>word2 <w:t>
    #       </w:r>
    #       <w:r>
    #         <w:rPr [bold italic]>
    #         <w:t>word3<w:t>
    #       </w:r>
    #       <w:r>
    #         <w:rPr [bold]>
    #         <w:t> word4<w:t>
    #       </w:r>
    #       <w:r>
    #         <w:t> word5<w:t>
    #       </w:r>
    #     </w:p>
    #
    # Spec for DOCX: http://officeopenxml.com/anatomyofOOXML.php
    class Docx < Base

      # Custom error.
      class Exception < RuntimeError; end
      # Custom error for unhandled kramdown elements.
      class InvalidElementException < Exception; end

      # Maps Kramdown block level elements to paragraph styles.
      # @return [Hash{String => Hash}] Hash with block_level element descriptors as keys and
      #   paragraph style attributes as values.
      #   * id        'Heading1'  # sets the internal identifier for the style.
      #   * name      'heading 1' # sets the friendly name of the style.
      #   * font      'Palantino' # sets the font family.
      #   * color     '333333'    # sets the text color. accepts hex RGB.
      #   * size      28          # sets the font size. units in half points.
      #   * bold      false       # sets the font weight.
      #   * italic    false       # sets the font style.
      #   * underline false       # sets whether or not to underline the text.
      #   * caps      false       # sets whether or not text should be rendered in all capital letters.
      #   * align     :left       # sets the alignment. accepts :left, :center, :right, and :both.
      #   * line      360         # sets the line height. units in twips.
      #   * top       100         # sets the spacing above the paragraph. units in twips.
      #   * bottom    0           # sets the spacing below the paragraph. units in twips.
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
          'hr' => {
            name: 'Horizontal rule',
            id: 'horizontalRule',
            size: 12,
            align: :left,
            line: 160,
            top: 12,
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
          'p.test' => {
            name: 'Paragraph Test',
            id: 'paraTest',
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
      # @param options [Hash{Symbol => Object}]
      def initialize(root, options = {})
        super
        @rt_options = options
        @rt_current_document = nil # initialized in convert_root
        @rt_current_block_node = nil # para, header, hr
        @rt_run_context = OpenStruct.new(
          inside_a_run: false,
          collected_text: '',
          run_attributes_stack: []
        )
      end

      # Converts ke and causes side effects on @current_[document|paragraph|run]
      # @param ke [Kramdown::Element]
      def convert(ke)
        send(DISPATCHER[ke.type], ke)
      end

      # @return [String] the name of the converter method for kramdown element_type
      DISPATCHER = Hash.new { |h,element_type|
        h[element_type] = "convert_#{ element_type }"
      }

      # Converts ke's child elements
      # @param ke [Kramdown::Element]
      def inner(ke)
        ke.children.each { |child| convert(child) }
      end

    protected

      # Adds text either to @rt_current_block_node or @rt_run_context.collected_text_for_current_run
      # @param text [String]
      def add_text(text)
        if @rt_run_context.inside_a_run
          # We're inside a span, append contents
          @rt_run_context.collected_text << text
        else
          # This is a text node not inside an em. Create a run.
          @rt_current_block_node.text(text)
        end
      end

      # Call this method at the beginning of every convert_[block el] method
      # to make sure that no text runs are active.
      def check_that_no_text_run_is_active
        if @rt_run_context.inside_a_run
          raise "Unexpected run! #{ @rt_run_context.inspect }"
        end
      end

      # Computes a hash with text run attributes based on em_classes
      # @param em_classes [Array<String>]
      def compute_text_run_attrs_from_em(em_classes)
        # Handle em with no classes: results in plain italics
        return { italic: true } if em_classes.empty?
        r = {}
        r[:bold] = true  if em_classes.include?('bold')
        r[:italic] = true  if em_classes.include?('italic')
        r[:small_caps] = true  if em_classes.include?('smcaps')
        r[:underline] = true  if em_classes.include?('underline')
        r[:vert_align] = 'subscript'  if em_classes.include?('subscript')
        r[:vert_align] = 'superscript'  if em_classes.include?('superscript')
        r
      end

      # @param ke [Kramdown::Element]
      def convert_br(ke)
        @rt_current_block_node.br
      end

      # @param ke [Kramdown::Element]
      def convert_em(ke)
        # We ignore .line_break spans and their contents
        return ''  if ke.has_class?('line_break')

        text_run_start(compute_text_run_attrs_from_em(ke.get_classes))
        inner(ke)
        text_run_finalize
      end

      # @param ke [Kramdown::Element]
      def convert_entity(ke)
        # TODO: decide if we want to decode entities
        add_text(Repositext::Utils::EntityEncoder.decode(ke.options[:original]))
      end

      # @param ke [Kramdown::Element]
      def convert_gap_mark(ke)
        # Nothing to do
      end

      # @param ke [Kramdown::Element]
      def convert_header(ke)
        check_that_no_text_run_is_active
        header_style_id = case ke.options[:level]
        when 1 then paragraph_style_mappings['header-1'][:id]
        when 2 then paragraph_style_mappings['header-2'][:id]
        when 3 then paragraph_style_mappings['header-3'][:id]
        else
          raise InvalidElementException, "DOCX converter can't output header with levels != 1 | 2 | 3"
        end
        @rt_current_document.p do |p|
          @rt_current_block_node = p
          p.style(header_style_id)
          inner(ke)
          @rt_current_block_node = nil
        end
      end

      # NOTE: We don't use Caracal's `docx#hr` method. It just renders an
      # empty paragraph with a top border. It doesn't allow assignment of
      # any classes/styles. This makes it hard to parse. So we implement our own
      # version of this with the added ability to assign a style/class.
      # @param ke [Kramdown::Element]
      def convert_hr(ke)
        check_that_no_text_run_is_active
        @rt_current_document.p do |p|
          @rt_current_block_node = p
          p.style(paragraph_style_mappings['hr'][:id])
          inner(ke)
          @rt_current_block_node = nil
        end
      end

      # @param ke [Kramdown::Element]
      def convert_p(ke)
        check_that_no_text_run_is_active
        el_classes = (ke.attr['class'] || '').split
        para_style_id = if el_classes.any?
          # para has class
          para_style_mapping_ids = el_classes.map { |e|
            paragraph_style_mappings["p.#{ e }"]
          }.compact.map{ |e| e[:id] }
          case para_style_mapping_ids.size
          when 0
            # No mappings found
            raise(
              InvalidElementException.new(
                "DOCX converter can't output p with class #{ el_classes.inspect }"
              )
            )
          when 1
            # Exactly one mapping found
            para_style_mapping_ids.first
          else
            # Multiple mappings found
            raise(
              InvalidElementException.new(
                "DOCX converter found multiple paragraph mapping ids for #{ el_classes.inspect }: #{ para_style_mapping_ids.inspect }"
              )
            )
          end
        else
          # para doesn't have class
          nil
        end
        # Hook to add specialized behavior in sub classes
        convert_p_additions(ke)
        @rt_current_document.p do |p|
          @rt_current_block_node = p
          p.style(para_style_id)  if para_style_id
          inner(ke)
          @rt_current_block_node = nil
        end
      end

      # Hook to add specialized behavior to convert_p.
      def convert_p_additions(ke)
        # Override in subclasses.
      end

      # @param ke [Kramdown::Element]
      def convert_record_mark(ke)
        # Pull element
        check_that_no_text_run_is_active
        inner(ke)
      end

      # Writes a DOCX file to disk (using @rt_options[:output_file_name]).
      # @param ke [Kramdown::Element] the kramdown root element
      # @return [? String with filename or outcome?]
      def convert_root(ke)
        output_filename = @rt_options[:output_filename]
        if '' == output_filename.to_s.strip
          raise ArgumentError.new("Invalid option :output_filename: #{ output_filename.inspect }")
        end
        # Caracal expects a relative path
        caracal_base_path = File.expand_path('./')
        rel_output_path = Repositext::RFile.relative_path_from_to(
          caracal_base_path,
          output_filename
        )

        FileUtils.mkdir_p(File.dirname(output_filename))
        Caracal::Document.save(rel_output_path) do |docx|
          @rt_current_document = docx
          # Add style definitions
          paragraph_style_mappings.each do |_, style_attrs|
            docx.style(style_attrs)
          end
          # All convert methods are based on side effects on docx, not return values
          inner(ke)
          check_that_no_text_run_is_active
          @rt_current_document = nil
        end
      end

      # @param ke [Kramdown::Element]
      def convert_strong(ke)
        text_run_start(bold: true)
        inner(ke)
        text_run_finalize
      end

      # @param ke [Kramdown::Element]
      def convert_subtitle_mark(ke)
        # Nothing to do
      end

      # @param ke [Kramdown::Element]
      def convert_text(ke)
        txt = ke.value.gsub(/\n/, ' ') # Remove newlines from text nodes.
        add_text(txt)
      end

      # @param ke [Kramdown::Element]
      def convert_xml_comment(ke)
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

      # Delegate to class method
      def paragraph_style_mappings
        self.class.paragraph_style_mappings
      end

      # Finalizes current text run if it exists and starts a new (nested one).
      # @param run_attrs [Hash{Symbol => Object}]
      def text_run_continue_existing
        if @rt_run_context.run_attributes_stack.any?
          # Prepare attrs for new run (will be added to docx in finalize method)
          @rt_run_context.inside_a_run = true
        end
        true
      end

      # Finalizes current text run if it exists.
      # @param preserve_run_attrs [Boolean] Defaults to false, discarding the
      #   last run's attributes. Set to true for nested spans where we want to
      #   preserve outer attrs for when inner span closes.
      def text_run_finalize
        if '' != @rt_run_context.collected_text
          # Add run only if we collected any text
          @rt_current_block_node.text(
            @rt_run_context.collected_text,
            @rt_run_context.run_attributes_stack.last
          )
        end
        # Reset run_context
        @rt_run_context.collected_text = ''
        @rt_run_context.inside_a_run = false
        @rt_run_context.run_attributes_stack.pop

        text_run_continue_existing
        true
      end

      # Called whenever we start a new text_run. The source span may be nested
      # inside another span.
      def text_run_interrupt_existing
        if @rt_run_context.inside_a_run
          if '' != @rt_run_context.collected_text
            # Add run only if we collected any text
            @rt_current_block_node.text(
              @rt_run_context.collected_text,
              @rt_run_context.run_attributes_stack.last
            )
          end
          # Reset run_context
          @rt_run_context.collected_text = ''
          @rt_run_context.inside_a_run = false
        end
        true
      end

      # Finalizes current text run if it exists and starts a new (nested one).
      # @param run_attrs [Hash{Symbol => Object}]
      def text_run_start(run_attrs)
        # Finalize any currently active text run, preserve its run_attrs
        text_run_interrupt_existing
        # Prepare attrs for new run (will be added to docx in finalize method)
        @rt_run_context.inside_a_run = true
        @rt_run_context.run_attributes_stack.push(
          (@rt_run_context.run_attributes_stack.last || {}).merge(run_attrs)
        )
        true
      end

    end

  end
end
