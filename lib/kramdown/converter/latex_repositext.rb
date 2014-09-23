module Kramdown
  module Converter
    # Converts an element tree to Latex. Adds converting of repositext specific
    # tokens. Returns just latex body. Needs to be wrapped in a complete latex
    # document.
    class LatexRepositext < Latex

      class LeftoverTempGapMarkError < StandardError; end

      # Since our font doesn't have a small caps variant, we have to emulate it
      # for latex.
      # This is a class method so that we can easily use it from other places.
      def self.emulate_small_caps(txt)
        # wrap all groups of lower case characters (not latex commands!) in RtSmCapsEmulation command
        r = txt.gsub(
          /
            ( # wrap in capture group so that we can access it for replacement
              (?<![\\[:lower:]]) # negative lookbehind for latex commands like emph
              [[:lower:]]+ # capture all lower case letters
            )
          /x,
        ) { |e|
          # NOTE: We should make #upcase locale specific (using 2-letter lang code).
          # See UnicodeUtils gem for details:
          # https://github.com/lang/unicode_utils#synopsis
          %(\\RtSmCapsEmulation{#{ UnicodeUtils.upcase(e) }})
        }
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
          if el.has_class?('smcaps')
            inner_text = self.class.emulate_small_caps(inner(el, opts))
          end
          if el.has_class?('pn')
            # render as paragraph number
            before << '\\RtParagraphNumber{'
            after << '}'
          end
        end
        "#{ before }#{ inner_text || inner(el, opts) }#{ after }"
      end

      # Override this method in any subclasses that render gap_marks
      def convert_gap_mark(el, opts)
        ''
      end

      # Patch this method to render headers without using latex title
      def convert_header(el, opts)
        r = break_out_of_song(@inside_song)
        case output_header_level(el.options[:level])
        when 1
          # render in RtTitle environment
          l_title = inner(el, opts)
          @document_title ||= l_title # capture first level 1 header as document title
          r << "\\begin{RtTitle}\n#{self.class.emulate_small_caps(l_title) }\n\\end{RtTitle}"
        when 3
          # render in RtSubTitle environment
          r << "\\begin{RtSubTitle}\n#{ inner(el, opts) }\n\\end{RtSubTitle}"
        else
          raise "Unhandled header type: #{ el.inspect }"
        end
        r
      end

      # Patch this method to handle the various repositext paragraph styles.
      def convert_p(el, opts)
        if el.children.size == 1 && el.children.first.type == :img && !(img = convert_img(el.children.first, opts)).empty?
          convert_standalone_image(el, opts, img)
        else
          before = ''
          after = ''
          inner_text = nil

          if @inside_song
            case
            when el.has_class?('stanza')
              # close current RtSong environment, open new one
              before << break_out_of_song(true)
              before << "\n\\begin{RtSong}\n"
              @inside_song = true # set @inside_song back to true
              # leave @inside_song true
              # TODO: print warning, this shouldn't really happen
            when el.has_class?('song')
              # nothing to do, just continue with current RtSong environment
            else
              # close RtSong environment
              before << break_out_of_song(true)
              @inside_song = false
            end
          end

          # Have to process Songs before any other classes because of
          # nested environments. Songs can span multiple paragraphs, so they
          # need to be the outermost nesting.
          if el.has_class?('song')
            # TODO: what to do here? raise warning if not @inside_song?
          end
          if el.has_class?('stanza')
            if !@inside_song
              # start new RtSong environment
              before << "\\begin{RtSong}\n"
              @inside_song = true
            else
              # case where we're @inside_song is handled higher up
            end
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
            # emulate small caps
            inner_text = self.class.emulate_small_caps(inner(el, opts))
            # differentiate between primary and non-primary repos
            if !@options[:is_primary_repo]
              # add space between title and date code
              inner_text.gsub!(/ [[:alpha:]]{3}\d{2}\-\d{4}/, '\\hspace{2 mm}\0')
              # make date code smaller
              inner_text.gsub!(/(?<= )[[:alpha:]]{3}\d{2}\-\d{4}.+/, '\textscale{0.8}{\0}')
            end
          end
          if el.has_class?('id_title2')
            # render in RtIdTitle2 environment
            before << "\\begin{RtIdTitle2}\n"
            after << "\n\\end{RtIdTitle2}"
          end
          if el.has_class?('normal')
          end
          if el.has_class?('normal_pn')
          end
          if el.has_class?('omit')
            # render in RtOmit environment
            b,a = latex_environment_for_translator_omit
            before << b
            after << a
          end
          if el.has_class?('scr')
            # render in RtScr environment
            before << "\\begin{RtScr}\n"
            after << "\n\\end{RtScr}"
          end
          "#{ before }#{ inner_text || inner(el, opts) }#{ after }\n\n"
        end
      end

      # Override this method in any subclasses that render record_marks
      def convert_record_mark(el, opts)
        r = break_out_of_song(@inside_song)
        r << inner(el, opts)
        r
      end

      # Returns a complete latex document as string.
      # @param[Kramdown::Element] el the kramdown root element
      # @param[Hash] opts
      # @return[String]
      def convert_root(el, opts)
        @inside_song = false # maintain song wrapping state
        latex_body = inner(el, opts)
        latex_body << break_out_of_song(@inside_song) # close any open song environments
        latex_body = post_process_latex_body(latex_body)
        document_title = (@document_title || '[Untitled]').strip.gsub(/\A\\emph\{(.+)\}/, '\1') # strip surrounding \emph latex command
        wrap_body_in_template(latex_body, document_title)
      end

      def convert_strong(el, opts)
        if 'V-Calisto-St' == @options[:font_name]
          # NOTE: There is a strange bug where in the V-Calisto-St font and latex
          # bold and bold-italic are reversed. So whenever I want bold, I have to
          # specify bold-italic and vice versa.
          "\\textit{\\textbf{#{ inner(el, opts) }}}"
        else
          "\\textbf{#{ inner(el, opts) }}"
        end
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
      def wrap_body_in_template(latex_body, document_title)
        latex_body
      end

      # @param[String] latex_body
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
              ){0,2} # repeat up to two times to match "\<gap-mark>\(\emph{others}"
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
        # eagle: replace eagle with latex command for custom formatting
        lb.gsub!(//, "\\RtEagle")
        # eagle: force space after leading eagle
        lb.gsub!(/(?<=\\RtEagle)\ /, '\\ ')
        # Decode entity encoded chars
        lb = Repositext::Utils::EntityEncoder.decode(lb)
        lb
      end

      # Override this method in any subclasses that render paragraphs with class
      # `.omit`.
      # Return an array of complete `begin` and `end` latex commands.
      def latex_environment_for_translator_omit
        ['', '']
      end

      # Returns a snippet that will break out of a song block if inside_song is true.
      # @param[Boolean] inside_song set to true to force closing of song env.
      #     falls back to @inside_song state variable.
      def break_out_of_song(inside_song)
        if inside_song
          @inside_song = false
          "\\end{RtSong}\n"
        else
          ''
        end
      end

    end

  end

end
