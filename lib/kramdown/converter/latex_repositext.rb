module Kramdown
  module Converter
    # Converts a kramdown element tree to a Latex body string.
    # This is used to produce PDF documents.
    # Adds converting of repositext specific tokens.
    # Returns just latex body. Needs to be wrapped in a complete latex
    # document.
    class LatexRepositext < Latex

      include PostProcessLatexBodyMixin

      # Custom error
      class LeftoverTempGapMarkError < StandardError; end
      # Custom error
      class LeftoverTempGapMarkNumberError < StandardError; end

      # Since our font doesn't have a small caps variant, we have to emulate it
      # for latex.
      # We wrap all groups of lower case characters in the \RtSmCapsEmulation command.
      # We apply custom kerning at the beginning and end of each smallcaps
      # emulated span since Latex' regular kerning doesn't work there.
      # We even apply inter-word kerning to characters that are separated by a space.
      #
      # @param txt [String] the text inside the em.smcaps.
      # @param font_name [String]
      # @param font_attrs [Array<String>]
      # @return [String]
      def emulate_small_caps(txt, font_name, font_attrs)
        debug = false

        if debug
          puts
          p txt
          p [font_name, font_attrs]
        end

        if txt =~ /\A[[:alpha:]]\z/
          # This is a single character, part of a date code
          return %(\\RtSmCapsEmulation{none}{#{ txt.unicode_upcase }}{none})
        end

        new_string = ""
        font_attrs = font_attrs.compact.sort.join(' ')
        str_sc = StringScanner.new(txt)

        str_sc_state = :start
        keep_scanning = true

        while keep_scanning do
          puts("#{ str_sc_state.inspect } - #{ str_sc.rest.inspect }")  if debug
          case str_sc_state
          when :start
            leading_chars = nil
            smallcaps_chars = nil
            following_char = nil

            leading_kerning_value = nil
            trailing_kerning_value = nil

            str_sc_state = :capture_leading_chars
          when :capture_leading_chars
            if str_sc.scan(/\s+/)
              # Consume leading space chars.
              new_string << str_sc.matched
              puts("  #{ str_sc.matched.inspect }")  if debug
            elsif str_sc.scan(/[^[:lower:]\s]+/)
              # Capture leading non-lowercase chars.
              leading_chars = str_sc.matched
              new_string << leading_chars
              puts("  #{ leading_chars.inspect }")  if debug
            end
            str_sc_state = :capture_smallcaps_chars
          when :capture_smallcaps_chars
            # Capture lowercase chars for smallcaps emulation.
            if(str_sc.scan(/[[:lower:]]+/))
              smallcaps_chars = str_sc.matched
              puts("  #{ smallcaps_chars.inspect }")  if debug
            end
            str_sc_state = :detect_following_char
          when :detect_following_char
            # Peek at the following char (even if separated by space).
            if(str_sc.check(/\s?./))
              following_char = str_sc.matched.sub(' ', '')
              puts("  #{ following_char.inspect }")  if debug
            end
            str_sc_state = :finalize_smcaps_run
          when :finalize_smcaps_run
            # Process the string: apply custom kernings and wrap in smallcaps emulation command
            prev_char = (leading_chars || '')[-1]
            if prev_char && smallcaps_chars
              # Determine leading custom kerning
              leading_character_pair = [prev_char, smallcaps_chars[0]].join
              puts("  leading character pair: #{ leading_character_pair.inspect }")  if debug
              leading_kerning_value = smallcaps_kerning_map.lookup_kerning(
                font_name,
                font_attrs,
                leading_character_pair
              )
              if leading_kerning_value
                # We have a value, add `em` unit
                leading_kerning_value = "#{ leading_kerning_value }em"
              else
                # No kerning value, print out warning
                puts "Unhandled Kerning for font #{ font_name.inspect }, font_attrs #{ font_attrs.inspect } and character pair #{ leading_character_pair.inspect }, ".color(:red)
              end
            end
            # Determine trailing custom kerning
            end_char = (smallcaps_chars || leading_chars || '')[-1]
            if end_char && following_char
              trailing_character_pair = [end_char, following_char].join
              puts("  trailing character pair: #{ trailing_character_pair.inspect }")  if debug
              trailing_kerning_value = smallcaps_kerning_map.lookup_kerning(
                font_name,
                font_attrs,
                trailing_character_pair
              )
              if trailing_kerning_value
                # We have a value, add `em` unit
                trailing_kerning_value = "#{ trailing_kerning_value }em"
              else
                # No kerning value, print out warning
                puts "Unhandled Kerning for font #{ font_name.inspect }, font_attrs #{ font_attrs.inspect } and character pair #{ trailing_character_pair.inspect }, ".color(:red)
              end
            end

            if smallcaps_chars || leading_kerning_value || trailing_kerning_value
              new_string << [
                %(\\RtSmCapsEmulation), # latex command
                %({#{ leading_kerning_value || 'none' }}), # leading custom kerning argument
                %({#{ (smallcaps_chars || '').unicode_upcase }}), # text in smallcaps
                %({#{ trailing_kerning_value || 'none' }}), # trailing custom kerning argument
              ].join
            end
            if str_sc.eos?
              keep_scanning = false
            else
              str_sc_state = :start
            end
          else
            raise "Handle this: #{ str_sc_state.inspect }"
          end
        end
        p new_string  if debug
        new_string
      end

      # @return [Hash]
      def smallcaps_kerning_map
        @smallcaps_kerning_map ||= SmallcapsKerningMap.new
      end

      # Create a Latex converter with the given options.
      # @param root [Kramdown::Element]
      # @param options [Hash{Symbol => Object}]
      def initialize(root, options = {})
        super
        @element_ancestors_stack = ElementStack.new
      end

      # Patch this method to handle ems that came via imports:
      # When importing, :ems are used as container to apply a class to a span.
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_em(el, opts)
        # TODO: add mechanism to verify that we have processed all classes
        with_ancestors_stack(el) do
          before = ''
          after = ''
          inner_text = nil
          case
          when [nil, ''].include?(el.attr['class'])
            # em without class => convert to \emph{}
            before << '\\emph{'
            after << '}'
          else
            if el.has_class?('bold')
              before << '\\textbf{'
              after << '}'
            end
            if el.has_class?('italic')
              # em with classes, including .italic => convert to \emph{}. Other
              # places in this method will add environments for the additional
              # classes.
              # We use latex's \emph command so that it toggles between regular
              # and italic, depending on context. This way italic will be rendered
              # as regular in an italic context (e.g., .scr)
              before << '\\emph{'
              after << '}'
            end
            if el.has_class?('line_break')
              # Insert a line break, ignore anything inside the em
              before << "\\linebreak\n"
              inner_text = ''
            end
            if el.has_class?('pn')
              # render as paragraph number
              before << '\\RtParagraphNumber{'
              after << '}'
            end
            if el.has_class?('smcaps')
              font_attrs = ['bold', 'italic'] & el.get_classes
              font_attrs = ['regular']  if font_attrs.empty?
              inner_text = emulate_small_caps(
                inner(el, opts),
                opts[:smallcaps_font_override] || @options[:font_name],
                font_attrs
              )
            end
            if el.has_class?('subscript')
              before << '\\textsubscript{'
              after << '}'
            end
            if el.has_class?('superscript')
              wrap_superscript(el, before, after, @element_ancestors_stack)
            end
          end
          "#{ before }#{ inner_text || inner(el, opts) }#{ after }"
        end
      end

      # Patch this method because kramdown's doesn't handle some of the
      # characters we need to handle.
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_entity(el, opts)
        # begin patch JH
        r = nil
        with_ancestors_stack(el) do
          entity = el.value # Kramdown::Utils::Entities::Entity
          # first let kramdown give it a shot
          r = entity_to_latex(entity)
          if '' == r
            # kramdown couldn't handle it
            r = if %w[200B 2011 2028 202F FEFF].include?(sprintf("%04X", entity.code_point))
              # decode valid characters
              Repositext::Utils::EntityEncoder.decode(el.options[:original])
            else
              # return empty string for invalid characters
              ''
            end
          end
        end
        r
        # end patch JH
      end

      # Override this method in any subclasses that render gap_marks
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_gap_mark(el, opts)
        ''
      end

      # Patch this method to render headers without using latex title
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_header(el, opts)
        with_ancestors_stack(el) do
          case output_header_level(el.options[:level])
          when 1
            # render in RtTitle environment
            l_title = inner(el, opts.merge(smallcaps_font_override: @options[:title_font_name]))
            # capture first level 1 header as document title
            @document_title_plain_text ||= el.to_plain_text
            @document_title_latex ||= l_title
            # Fix issue where superscript fontsize in RtTitle is not scaled down
            # Convert "\textsuperscript{1}"
            # To "\textsuperscript{\textscale{0.7}{1}}"
            l_title = l_title.gsub(
              /(?<=\\textsuperscript\{)([^\}]+)(?=\})/, "\\textscale{0.7}{" + '\1}'
            )
            # NOTE: We insert a percent sign immediately after l_title to prevent trailing whitespace
            # which would break the centering of the text.
            "\\begin{RtTitle}%\n#{ l_title }%\n\\end{RtTitle}"
          when 2
            # render in RtTitle2 environment
            l_title = inner(el, opts.merge(smallcaps_font_override: opts[:title_font_name]))
            # Fix issue where superscript fontsize in RtTitle is not scaled down
            # Convert "\textsuperscript{1}"
            # To "\textsuperscript{\textscale{0.7}{1}}"
            l_title = l_title.gsub(
              /(?<=\\textsuperscript\{)([^\}]+)(?=\})/, "\\textscale{0.7}{" + '\1}'
            )
            "\\begin{RtTitle2}\n#{ l_title }\n\\end{RtTitle2}"
          when 3
            # render in RtSubTitle environment
            "\\begin{RtSubTitle}\n#{ inner(el, opts) }\n\\end{RtSubTitle}"
          else
            raise "Unhandled header type: #{ el.inspect }"
          end
        end
      end

      # Patch this method to handle the various repositext paragraph styles.
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_p(el, opts)
        with_ancestors_stack(el) do
          if el.children.size == 1 && el.children.first.type == :img && !(img = convert_img(el.children.first, opts)).empty?
            convert_standalone_image(el, opts, img)
          else
            before = ''
            after = ''
            inner_text = nil

            # NOTE: We may wrap multiple environments around a single paragraph.
            # It's important that the latex environments are nested symmetrically.
            # So we we prepend to the `before` and append to the `after` string.
            if el.has_class?('decreased_word_space')
              # render in RtDecreasedWordSpace environment
              before.prepend("\\begin{RtDecreasedWordSpace}\n")
              after << "\n\\end{RtDecreasedWordSpace}"
            end
            if el.has_class?('first_par')
              # render in RtFirstPar environment
              before.prepend("\\begin{RtFirstPar}\n")
              after << "\n\\end{RtFirstPar}"
            end
            if el.has_class?('increased_word_space')
              # render in RtIncreasedWordSpace environment
              before.prepend("\\begin{RtIncreasedWordSpace}\n")
              after << "\n\\end{RtIncreasedWordSpace}"
            end
            if el.has_class?('indent_for_eagle')
              # render in RtIndentForEagle environment
              before.prepend("\\begin{RtIndentForEagle}\n")
              after << "\n\\end{RtIndentForEagle}"
            end
            if el.has_class?('id_paragraph')
              # render in RtIdParagraph environment
              before.prepend("\\begin{RtIdParagraph}\n")
              after << "\n\\end{RtIdParagraph}"
            end
            if el.has_class?('id_title1')
              # render in RtIdTitle1 environment
              before.prepend("\\begin{RtIdTitle1}\n")
              after << "\n\\end{RtIdTitle1}"
              inner_text = inner(el, opts.merge(smallcaps_font_override: @options[:title_font_name]))
              # differentiate between primary and non-primary content_types
              if !@options[:is_primary_repo]
                # add space between title and date code
                inner_text.gsub!(/ ([[:alpha:]]{3}\d{2}\-\d{4})/, "\\" + 'hspace{2 mm}\1')
                # make date code smaller
                inner_text.gsub!(/[[:alpha:]]{3}\d{2}\-\d{4}.*/, "\\" + 'textscale{0.8}{\0}')
              end
            end
            if el.has_class?('id_title2')
              # render in RtIdTitle2 environment
              before.prepend("\\begin{RtIdTitle2}\n")
              after << "\n\\end{RtIdTitle2}"
              inner_text = inner(el, opts.merge(smallcaps_font_override: @options[:title_font_name]))
            end
            if el.has_class?('normal')
              # render in RtNormal environment
              before.prepend("\\begin{RtNormal}\n")
              after << "\n\\end{RtNormal}"
            end
            if el.has_class?('normal_pn')
              # render in RtNormal environment
              before.prepend("\\begin{RtNormal}\n")
              after << "\n\\end{RtNormal}"
            end
            if el.has_class?('omit')
              # render in RtOmit environment
              b,a = latex_environment_for_translator_omit
              before.prepend(b)
              after << a
            end
            if el.has_class?('q')
              # render in RtQuestion environment
              before.prepend("\\begin{RtQuestion}\n")
              after << "\n\\end{RtQuestion}"
            end
            if el.has_class?('scr')
              # render in RtScr environment
              before.prepend("\\begin{RtScr}\n")
              after << "\n\\end{RtScr}"
            end
            if el.has_class?('song')
              # render in RtSong environment
              before.prepend("\\begin{RtSong}\n")
              after << "\n\\end{RtSong}"
            end
            if el.has_class?('song_break')
              # render in RtSong(Break) environment
              latex_env = apply_song_break_class ? 'RtSongBreak' : 'RtSong'
              before.prepend("\\begin{#{ latex_env }}\n")
              after << "\n\\end{#{ latex_env }}"
            end
            if el.has_class?('stanza')
             # render in RtStanza environment
              before.prepend("\\begin{RtStanza}\n")
              after << "\n\\end{RtStanza}"
            end
            "#{ before }#{ inner_text || inner(el, opts) }#{ after }\n\n"
          end
        end
      end

      # Override this method in any subclasses that render record_marks
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_record_mark(el, opts)
        with_ancestors_stack(el) do
          inner(el, opts)
        end
      end

      # Returns a complete latex document as string.
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      # @return [String]
      def convert_root(el, opts)
        with_ancestors_stack(el) do
          latex_body = inner(el, opts)
          latex_body = post_process_latex_body(latex_body)
          document_title_plain_text = (
            @document_title_plain_text || '[Untitled]'
          ).strip
          document_title_latex = (
            @document_title_latex || '[Untitled]'
          )
          r = wrap_body_in_template(latex_body, document_title_plain_text, document_title_latex)
          if @options[:debug]
            puts('---- Latex source code (start): ' + '-' * 40)
            puts r
            puts('---- Latex source code (end): ' + '-' * 40)
          end
          r
        end
      end

      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_strong(el, opts)
        with_ancestors_stack(el) do
          "\\textbf{#{ inner(el, opts) }}"
        end
      end

      # Override this method in any subclasses that render subtitle_marks
      # @param el [Kramdown::Element]
      # @param opts [Hash{Symbol => Object}]
      def convert_subtitle_mark(el, opts)
        ''
      end

    protected

      # Returns boolean to indicate whether song_break_class should be applied.
      def apply_song_break_class
        true
      end

      # Temporary placeholder for gap_mark number and text
      def tmp_gap_mark_complete
        tmp_gap_mark_number + tmp_gap_mark_text
      end

      # Normally we don't render cue numbers with gap_marks. Override this in
      # converters that render cue numbers
      def tmp_gap_mark_number
        ''
      end

      # Temporary placeholder for gap_mark text
      def tmp_gap_mark_text
        "<<<gap-mark>>>"
      end

      # Manages the kramdown element ancestry stack.
      # @param el [Kramdown::Element] will be put on top of stack for duration of block.
      # @block will be called with el added as top element to stack.
      # @return [Object] returns whatever is returned from yielding to block.
      def with_ancestors_stack(el)
        @element_ancestors_stack.push(el)
        r = yield
        @element_ancestors_stack.pop
        r
      end

      # Override this method in any subclasses that wrap the latex body with
      # a preamble to make a complete latex document.
      def wrap_body_in_template(latex_body, document_title_plain_text, document_title_latex)
        latex_body
      end

      # Handles the various kinds of superscript, depending on el's ancestry.
      # @param el [Kramdown::Element] the span with class .superscript
      # @param before [String] collector for `before` text, modified in place.
      # @param after [String] collector for `after` text, modified in place.
      # @param kramdown_element_stack [Kramdown::ElementStack]
      def wrap_superscript(el, before, after, kramdown_element_stack)
        if kramdown_element_stack.inside_title?
          # Same for primary and foreign languages.
          # Reduce font size from 22pt to 9.5pt (0.432).
          # Raise so that top of a superscript `1` is top aligned with top of smallcaps chars.
          before << "{\\raisebox{0.4ex}{{\\textscale{0.432}{"
          after << "}}}}"
        elsif kramdown_element_stack.inside_id_title1?
          # Same for primary and foreign languages.
          # Reduce font size from 10pt to 5.6pt (0.560).
          # Raise so that top of a superscript `1` is top aligned with top of smallcaps chars
          before << "{\\raisebox{0.15ex}{{\\textscale{0.560}{"
          after << "}}}}"
        elsif kramdown_element_stack.inside_id_title2?
          # Not applicable to primary language.
          # Reduce font size from 8pt to 5pt (0.625).
          # Raise so that top of a superscript `1` is top aligned with top of upper case chars.
          before << "{\\raisebox{0.4ex}{{\\textscale{0.625}{"
          after << "}}}}"
        else
          # Use latex' superscript macro.
          before << '\\textsuperscript{'
          after << '}'
        end
      end

      # Override this method in any subclasses that render paragraphs with class
      # `.omit`.
      # Return an array of complete `begin` and `end` latex commands.
      def latex_environment_for_translator_omit
        ['', '']
      end

      # Returns a copy of txt with latex special characters escaped for latex.
      # Inspired by http://tex.stackexchange.com/a/34586
      # NOTE that Kramdown::Parser::Latex already escapes contents of :text
      # elements, so we don't need to do that again.
      # @param [String] txt
      # @return [String]
      def escape_latex_text(txt)
        return txt  unless txt.is_a?(String)
        r = txt.dup
        # Replace all backslashes with latex macro.
        r.gsub!(/\\/, "\\textbackslash")
        r.gsub!(/(\\textbackslash)?&/, '\\\&') # ampersand requires special escaping
        %w[% $ # _ { }].each { |char|
          r.gsub!(/(\\textbackslash)?#{ Regexp.escape(char) }/, "\\#{ char }")
        }
        r.gsub!('~', "\\textasciitilde")
        r.gsub!('^', "\\textasciicircum")
        r
      end

    end
  end
end
