module Kramdown
  module Converter
    # Converts an element tree to Latex. Adds converting of repositext specific
    # tokens. Returns just latex body. Needs to be wrapped in a complete latex
    # document.
    class LatexRepositext < Latex

      include PostProcessLatexBodyMixin

      class LeftoverTempGapMarkError < StandardError; end
      class LeftoverTempGapMarkNumberError < StandardError; end

      # Since our font doesn't have a small caps variant, we have to emulate it
      # for latex.
      # We wrap all groups of lower case characters in the \RtSmCapsEmulation command.
      #
      # Strategy:
      #
      # * Find any pairs of adjacent letters with transition from upper to lower
      #   case.
      # * Capture upper case character as fullcaps char (fullcaps_char).
      # * Capture all lower case characters (smallcaps_chars).
      # * Look up leading custom kerning for fullcaps_char/smallcaps_chars.first (leading_ck).
      # * Capture optional trailing character (either upper case letter or
      #   punctuation [.,?!:]) following immediately after smallcaps_chars for custom
      #   kerning (trailing_ck_char).
      # * If trailing_ck_char ? look up trailing custom kerning for
      #   smallcaps_chars.last/trailing_ck_char (trailing_ck).
      # * Upcase and wrap smallcaps_chars in RtSmCapsEmulation with leading_ck and
      #   optional trailing_ck arguments.
      #
      # @param txt [String] the text inside the em.smcaps.
      # @param font_name [String]
      # @param font_attrs [Array<String>]
      # @return [String]
      def emulate_small_caps(txt, font_name, font_attrs)
        if txt =~ /\A[[:alpha:]]\z/
          # This is a single character, part of a date code
          return %(\\RtSmCapsEmulation{none}{#{ txt.unicode_upcase }}{none})
        end

        new_string = ""
        font_attrs = font_attrs.compact.sort.join(' ')
        str_sc = StringScanner.new(txt)

        str_sc_state = :capture_non_letter_chars # take care of any leading non-letter chars
        fullcaps_char = nil
        smallcaps_chars = nil
        trailing_ck_char = nil
        keep_scanning = true

        while keep_scanning do
          case str_sc_state
          when :capture_non_letter_chars
            if str_sc.scan(/[^[:alpha:]]*/)
              # capture any leading non-letter chars
              new_string << str_sc.matched
            end
            str_sc_state = :idle
          when :idle
            fullcaps_char = nil
            smallcaps_chars = nil
            trailing_ck_char = nil
            if(str_sc.check(/(?=[[:upper:]][[:lower:]])/))
              str_sc_state = :capture_fullcaps_char
            elsif(str_sc.check(/(?=[[:lower:]])/))
              str_sc_state = :capture_smallcaps_chars
            elsif(str_sc.scan(/[[:upper:]][^[:lower:]]*/))
              # Capture upper case not followed by lower case
              new_string << str_sc.matched
            else
              keep_scanning = false
            end
          when :capture_fullcaps_char
            if(str_sc.scan(/[[:upper:]](?=[[:lower:]])/))
              fullcaps_char = str_sc.matched
              str_sc_state = :capture_smallcaps_chars
            else
              raise "Handle this!"
            end
          when :capture_smallcaps_chars
            if(str_sc.scan(/[[:lower:]]+/))
              # lowercase characters
              smallcaps_chars = str_sc.matched
              str_sc_state = :maybe_detect_trailing_ck_char
            else
              raise "Handle this!"
            end
          when :maybe_detect_trailing_ck_char
            if(str_sc.check(/[[:upper:]\.\,\?\!\:]/))
              trailing_ck_char = str_sc.matched
            end
            str_sc_state = :finalize_smcaps_run
          when :finalize_smcaps_run
            if fullcaps_char
              # Determine leading custom kerning
              leading_character_pair = [fullcaps_char, smallcaps_chars[0]].join
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
              new_string << fullcaps_char
            else
              leading_kerning_value = nil
            end
            # Determine trailing custom kerning
            if trailing_ck_char
              trailing_character_pair = [smallcaps_chars[-1], trailing_ck_char].join
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
            else
              trailing_kerning_value = nil
            end
            new_string << [
              %(\\RtSmCapsEmulation), # latex command
              %({#{ leading_kerning_value || 'none' }}), # leading custom kerning argument
              %({#{ smallcaps_chars.unicode_upcase }}), # text in smallcaps
              %({#{ trailing_kerning_value || 'none' }}), # trailing custom kerning argument
            ].join
            str_sc_state = :capture_non_letter_chars
          else
            raise "Handle this: #{ str_sc_state.inspect }"
          end
        end
        new_string
      end

      def smallcaps_kerning_map
        @smallcaps_kerning_map ||= SmallcapsKerningMap.new
      end

      # Patch this method to handle ems that came via imports:
      # When importing, :ems are used as container to apply a class to a span.
      def convert_em(el, opts)
        # TODO: add mechanism to verify that we have processed all classes
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
            before << '\\textsuperscript{'
            after << '}'
          end
        end
        "#{ before }#{ inner_text || inner(el, opts) }#{ after }"
      end

      # Patch this method because kramdown's doesn't handle some of the
      # characters we need to handle.
      def convert_entity(el, opts)
        # begin patch JH
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
        r
        # end patch JH
      end

      # Override this method in any subclasses that render gap_marks
      def convert_gap_mark(el, opts)
        ''
      end

      # Patch this method to render headers without using latex title
      def convert_header(el, opts)
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

      # Patch this method to handle the various repositext paragraph styles.
      def convert_p(el, opts)
        if el.children.size == 1 && el.children.first.type == :img && !(img = convert_img(el.children.first, opts)).empty?
          convert_standalone_image(el, opts, img)
        else
          before = ''
          after = ''
          inner_text = nil

          if el.has_class?('first_par')
            # render in RtFirstPar environment
            before << "\\begin{RtFirstPar}\n"
            after << "\n\\end{RtFirstPar}"
          end
          if el.has_class?('indent_for_eagle')
            # render in RtIndentForEagle environment
            before << "\\begin{RtIndentForEagle}\n"
            after << "\n\\end{RtIndentForEagle}"
          end
          if el.has_class?('id_paragraph')
            # render in RtIdParagraph environment
            before << "\\begin{RtIdParagraph}\n"
            after << "\n\\end{RtIdParagraph}"
          end
          if el.has_class?('id_title1')
            # render in RtIdTitle1 environment
            before << "\\begin{RtIdTitle1}\n"
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
            before << "\\begin{RtIdTitle2}\n"
            after << "\n\\end{RtIdTitle2}"
            inner_text = inner(el, opts.merge(smallcaps_font_override: @options[:title_font_name]))
          end
          if el.has_class?('normal')
            # render in RtNormal environment
            before << "\\begin{RtNormal}\n"
            after << "\n\\end{RtNormal}"
          end
          if el.has_class?('normal_pn')
            # render in RtNormal environment
            before << "\\begin{RtNormal}\n"
            after << "\n\\end{RtNormal}"
          end
          if el.has_class?('omit')
            # render in RtOmit environment
            b,a = latex_environment_for_translator_omit
            before << b
            after << a
          end
          if el.has_class?('q')
            # render in RtQuestion environment
            before << "\\begin{RtQuestion}\n"
            after << "\n\\end{RtQuestion}"
          end
          if el.has_class?('scr')
            # render in RtScr environment
            before << "\\begin{RtScr}\n"
            after << "\n\\end{RtScr}"
          end
          if el.has_class?('song')
            # render in RtSong environment
            before << "\\begin{RtSong}\n"
            after << "\n\\end{RtSong}"
          end
          if el.has_class?('song_break')
            # render in RtSong(Break) environment
            latex_env = apply_song_break_class ? 'RtSongBreak' : 'RtSong'
            before << "\\begin{#{ latex_env }}\n"
            after << "\n\\end{#{ latex_env }}"
          end
          if el.has_class?('stanza')
           # render in RtStanza environment
            before << "\\begin{RtStanza}\n"
            after << "\n\\end{RtStanza}"
          end
          "#{ before }#{ inner_text || inner(el, opts) }#{ after }\n\n"
        end
      end

      # Override this method in any subclasses that render record_marks
      def convert_record_mark(el, opts)
        inner(el, opts)
      end

      # Returns a complete latex document as string.
      # @param [Kramdown::Element] el the kramdown root element
      # @param [Hash{Symbol => Object}] opts
      # @return [String]
      def convert_root(el, opts)
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

      def convert_strong(el, opts)
        "\\textbf{#{ inner(el, opts) }}"
      end

      # Override this method in any subclasses that render subtitle_marks
      def convert_subtitle_mark(el, opts)
        ''
      end

    protected

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

      # Override this method in any subclasses that wrap the latex body with
      # a preamble to make a complete latex document.
      def wrap_body_in_template(latex_body, document_title_plain_text, document_title_latex)
        latex_body
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
