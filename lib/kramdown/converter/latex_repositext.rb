module Kramdown
  module Converter
    # Converts an element tree to Latex. Adds converting of repositext specific
    # tokens. Returns just latex body. Needs to be wrapped in a complete latex
    # document.
    class LatexRepositext < Latex

      class LeftoverTempGapMarkError < StandardError; end
      class LeftoverTempGapMarkNumberError < StandardError; end

      # Since our font doesn't have a small caps variant, we have to emulate it
      # for latex.
      # This is a class method so that we can easily use it from other places.
      def self.emulate_small_caps(txt)
        # wrap all groups of lower case characters and some punctuation
        # (not latex commands!) in RtSmCapsEmulation command
        r = txt.gsub(
          /
            ( # wrap in capture group so that we can access it for replacement
              (?<![\\[:lower:]]) # negative lookbehind for latex commands like emph
              [[:lower:]\.]+ # capture all lower case letters and periods
            )
          /x,
        ) { |e| %(\\RtSmCapsEmulation{#{ e.unicode_upcase }}) }
        r
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
            inner_text = self.class.emulate_small_caps(inner(el, opts))
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
          l_title = inner(el, opts)
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
          "\\begin{RtTitle}\n#{ l_title }%\n\\end{RtTitle}"
        when 2
          # render in RtTitle2 environment
          l_title = inner(el, opts)
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
            inner_text = inner(el, opts)
            # differentiate between primary and non-primary content_types
            if !@options[:is_primary_repo]
              # add space between title and date code
              inner_text.gsub!(/ [[:alpha:]]{3}\d{2}\-\d{4}/, "\\" + 'hspace{2 mm}\0')
              # make date code smaller
              inner_text.gsub!(/(?<= )[[:alpha:]]{3}\d{2}\-\d{4}.*/, "\\" + 'textscale{0.8}{\0}')
            end
          end
          if el.has_class?('id_title2')
            # render in RtIdTitle2 environment
            before << "\\begin{RtIdTitle2}\n"
            after << "\n\\end{RtIdTitle2}"
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
      # @param [Hash] opts
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

      # @param [String] latex_body
      def post_process_latex_body(latex_body)
        lb = latex_body.dup
        # gap_marks: Skip certain characters and find characters to highlight in red
        gap_mark_complete_regex = Regexp.new(Regexp.escape(tmp_gap_mark_complete))
        chars_to_skip = [
          Repositext::D_QUOTE_OPEN,
          Repositext::EM_DASH,
          Repositext::S_QUOTE_OPEN,
          ' ',
          '(',
          '[',
          '"',
          "'",
          '}',
          '*',
          '［', # chinese bracket
          '（', # chinese parens
          '一', # chinese dash
          '《', # chinese left double angle bracket
          '……', # chinese double ellipsis
        ].join
        lb.gsub!(
          /
            #{ gap_mark_complete_regex } # find tmp gap mark number and text
            ( # capturing group for first group of characters to be colored red
              #{ Repositext::ELIPSIS }? # optional ellipsis
            )
            ( # capturing group for characters that are not to be colored red
              (?: # find one of the following, use non-capturing group for grouping only
                [#{ Regexp.escape(chars_to_skip) }]+ # special chars or delimiters
                | # or
                \\[[:alnum:]]+\{ # latex command with opening {
                | # or
                \s+ # eagle followed by whitespace
              )* # any of these zero or more times to match nested latex commands
            )
            ( #  This will be colored red
              #{ Repositext::ELIPSIS }? # optional elipsis
              [[:alpha:][:digit:]’\-\?]+ # words
            )
          /x,
          # we move the tmp_gap_mark_number to the very beginning so that if we
          # have an ellipsis before a latex command, the gap_mark_number will be
          # in front of the entire section that is colored red.
          # \1: an optional ellipsis (colored red)
          # \2: an optional latex command or characters not to be colored red
          # \3: the text to be colored red
          # OPTIMIZATION: We could skip the first \RtGapMarkText if \1 is blank
          tmp_gap_mark_number + "\\RtGapMarkText" + '{\1}' + '\2' + "\\RtGapMarkText" + '{\3}'
        )
        # Move tmp_gap_mark_number to outside of quotes, parentheses and brackets
        if !['', nil].include?(tmp_gap_mark_number)
          gap_mark_number_regex = Regexp.new(Regexp.escape(tmp_gap_mark_number))
          chars_to_move_outside_of = [
            Repositext::APOSTROPHE,
            Repositext::D_QUOTE_OPEN,
            Repositext::S_QUOTE_OPEN,
            '(',
            '[',
          ].join
          lb.gsub!(
            /
              ( # capturing group for characters to move outside of
                [#{ Regexp.escape(chars_to_move_outside_of) }]*
              )
              #{ gap_mark_number_regex } # find tmp gap mark number
            /x,
            "\\RtGapMarkNumber" + '\1' # Reverse order
          )
        end
        # Make sure no tmp_gap_marks are left
        if(ltgm = lb.match(/.{0,10}#{ Regexp.escape(tmp_gap_mark_text) }.{0,10}/))
          raise(LeftoverTempGapMarkError.new("Leftover temp gap mark: #{ ltgm.to_s.inspect }"))
        end
        if !['', nil].include?(tmp_gap_mark_number)
          if(ltgmn = lb.match(/.{0,10}#{ Regexp.escape(tmp_gap_mark_number) }.{0,10}/))
            raise(LeftoverTempGapMarkNumberError.new("Leftover temp gap mark number: #{ ltgmn.to_s.inspect }"))
          end
        end

        # Replace leading and trailing eagles with latex command/environment for
        # custom formatting
        # NOTE: Do this after processing gap_marks
        lb.gsub!(
          /
            ( # first capture group
              ^ # beginning of line
              # NOTE we do not expect any subtitle marks in latex
              (?: # non capture group
                #{ Regexp.escape("\\RtGapMarkText{}") }
              )? # optional
            )
             # eagle
            \s* # zero or more whitespace chars
            ( # second capture group
              [^]{10,} # at least ten non eagle chars
            )
            (?!$) # not followed by line end
          /x,
          '\1' + "\\RtFirstEagle " + '\2' # we use an environment for first eagle
        )
        lb.gsub!(
          /
            (?!<^) # not preceded by line start
            ( # first capture group
              [^]{10,} # at least ten non eagle chars
            )
            \s* # zero or more whitespace chars
             # eagle
            ( # second capture group
              [^]{,3} # up to three non eagle chars
              $ # end of line
            )
          /x,
          '\1' + " \\RtLastEagle{}" + '\2' # we use a command for last eagle
        )

        # Don't break lines between double open quote and apostrophe (via ~)
        lb.gsub!(
          "#{ Repositext::D_QUOTE_OPEN } #{ Repositext::APOSTROPHE }",
          "#{ Repositext::D_QUOTE_OPEN }~#{ Repositext::APOSTROPHE }"
        )
        # Remove space after paragraph number to avoid fluctuations in indent
        lb.gsub!(/(\\RtParagraphNumber\{[^\}]+\})\s*/, '\1')
        # Insert zero-width space after all elipses, emdashes, and hyphens.
        # This gives latex the option to break a line after these characters.
        # \hspace{0pt} is the latex equivalent of zero-width space (&#x200B;)
        line_breakable_chars = Regexp.escape(
          [Repositext::ELIPSIS, Repositext::EM_DASH, '-'].join
        )
        # Exceptions: Don't insert zero-width space if followed by no-break characters:
        no_break_following_chars = Regexp.escape(
          [Repositext::S_QUOTE_CLOSE, Repositext::D_QUOTE_CLOSE, ')?,!'].join
        )
        # We only want to allow linebreak _after_ line_breakable_chars so we
        # insert \nolinebreak _before_.
        # TODO: Move the Editor and Translator abbreviation exceptions to data.json
        lb.gsub!(
          /
            (
              [#{ line_breakable_chars }]
            )
            (?!
              (
                [#{ no_break_following_chars }]
                |
                (ed\.|n\.d\.t\.)
              )
            )
          /ix,
          "\\nolinebreak[4]"+'\1'+"\\hspace{0pt}"
        )

        # Convert any zero-width spaces to latex equivelant
        lb.gsub!(/\u200B/, "\\hspace{0pt}")
        lb
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
        r.gsub!(/(?<!\\)\&/, '\\\&') # ampersand requires special escaping
        %w[% $ # _ { }].each { |char|
          r.gsub!(/(?<!\\)#{ Regexp.escape(char) }/, "\\#{ char }")
        }
        r.gsub!('~', "\\textasciitilde")
        r.gsub!('^', "\\textasciicircum")
        # NOTE: we should also escape backslashes, however the only case we use
        # backslashes is for escaping, so we won't do that. Otherwise it would
        # break all the escaped other characters.
        r
      end

    end

  end

end
