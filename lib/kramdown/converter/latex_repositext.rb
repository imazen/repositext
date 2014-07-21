module Kramdown
  module Converter
    # Converts an element tree to Latex. Adds converting of repositext specific
    # tokens. Returns just latex body. Needs to be wrapped in a complete latex
    # document.
    class LatexRepositext < Latex

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
            inner_text = emulate_small_caps(inner(el, opts))
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
          r << "\\begin{RtTitle}\n#{ emulate_small_caps(inner(el, opts)) }\n\\end{RtTitle}"
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
            inner_text = emulate_small_caps(inner(el, opts))
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
        wrap_body_in_template(latex_body)
      end

      # Override this method in any subclasses that render subtitle_marks
      def convert_subtitle_mark(el, opts)
        ''
      end

      def latex_command_for_gap_mark
        '\\RtGapMark'
      end

    protected

      # Since our font doesn't have a small caps variant, we have to emulate it
      # for latex.
      def emulate_small_caps(txt)
        cap_groups = txt.split(/([[:lower:]](?=[[:upper:]])|[[:upper:]](?=[[:lower:]]))/)
                        .find_all { |e| e != '' }
        r = cap_groups.map { |e|
          case e
          when /\A[[:lower:]]/
            # wrap in RtSmCapsEmulation command and convert to upper case
            %(\\RtSmCapsEmulation{#{ e.upcase }})
          when /\A[[:upper:]]/
            # no modification, leave as is
            e
          else
            # leave as is (this is digits, latex commands, puncuation, etc.)
            e
          end
        }.join
      end

      # Override this method in any subclasses that wrap the latex body with
      # a preamble to make a complete latex document.
      def wrap_body_in_template(latex_body)
        latex_body
      end

      # @param[String] latex_body
      def post_process_latex_body(latex_body)
        lb = latex_body.dup
        # post process gap_marks
        gap_mark_regex = Regexp.new(Regexp.escape(TMP_GAP_MARK))
        lb.gsub!(/
            #{ gap_mark_regex } # find gap mark
            ( # capturing group for characters that are not to be colored red
              (?: # find one of the following, use non-capturing group for grouping only
                [\ \(\[\"\'\}\-#{ Regexp.escape(Repositext::ALL_TYPOGRAPHIC_CHARS.join) }\*]+ # special char or delimiter, we need closing brace because sometimes the tmp gap mark ends up inside an emph span
                | # or
                \\[[:alnum:]]+\{ # latex command with opening {
                | # or
                \s+ # eagle followed by whitespace
              ){0,2} # repeat up to two times to match "\<gap-mark>\(\emph{others}"
            )
            ([[:alpha:][:digit:]’]+) # find letters, numbers, or apostrophes. This will be colored red
          /x,
          '\1' + latex_command_for_gap_mark + '{\2}'
        )
        # replace eagle with latex command for custom formatting
        lb.gsub!(//, "\\RtEagle")
        lb.gsub!(/(?<=\\RtEagle)\ /, '\\ ') # force space after leading eagle
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
