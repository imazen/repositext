module Kramdown
  module Converter
    class LatexRepositext
      # Namespace for methods related to PDF document level methods.
      module DocumentMixin

        # Create an LatexRepositext Document converter with the given options.
        # @param [Kramdown::Element] root
        # @param [Hash{Symbol => Object}] options
        def initialize(root, options = {})
          super
          # NOTE: kramdown initializes all options with default values. So
          # :template_file is initialized to Nil. This breaks
          # @options = { <defaults> }.merge(options), so I have to set them like below.
          # TODO: when unifying class API, move files out of the classes into caller?
          # options[:template_file] ||= latex_template_path
          @options = options
        end

        # Determines if meta_info is included in PDF. Override in subclasses.
        def include_meta_info
          true
        end

        # Returns latex_template as ERB string
        def latex_template
          @latex_template ||= File.new(
            File.expand_path("../../../../../templates/latex_for_pdf.erb", __FILE__),
            'r'
          ).read
        end

        # Configure page settings. All values are in inches
        def page_settings(key)
          # We use #fetch instead of #[] so that an exception is raised on
          # non-existing keys.
          # We need `english_bound` for englarged copies because the text box
          # is different between bound and stitched in english.
          # All foreign files are forced to stitched since text boxes between
          # bound and stitched are identical. That way we have a single
          # source of data and no duplication.
          {
            english_bound: {
              paperwidth: '8.5truein',
              paperheight: '11truein',
              inner: '1.304655truein',
              outer: '1.345345truein',
              top: '1.06154truein',
              bottom: '0.66855truein',
              headsep: '0.1106in', # We want this dimension to scale with geometry package \mag.
              footskip: '0.351in', # We want this dimension to scale with geometry package \mag.
            },
            english_stitched: {
              paperwidth: '8.5truein',
              paperheight: '11truein',
              inner: '1.304655truein',
              outer: '1.345345truein',
              top: '1.06154truein',
              bottom: '0.66855truein',
              headsep: '0.1106in', # We want this dimension to scale with geometry package \mag.
              footskip: '0.351in', # We want this dimension to scale with geometry package \mag.
            },
            foreign_stitched: {
              paperwidth: '8.5truein',
              paperheight: '11truein',
              inner: '1.528125truein',
              outer: '1.555165truein',
              top: '1.04425truein',
              bottom: '0.70715truein',
              headsep: '0.172in', # We want this dimension to scale with geometry package \mag.
              footskip: '0.25in', # We want this dimension to scale with geometry package \mag.
            },
          }.fetch(key)
        end

        # Returns the default language to use with polyglossia or nil if we don't
        # need to use polyglossia for the given language.
        # @param language_code_3_chars [String]
        # @return [String, Nil]
        # TODO: Move this into settings or `Language` classes
        def polyglossia_default_language(language_code_3_chars)
          {
            'ara' => 'arabic',
            'frs' => 'farsi',
            'kan' => 'kannada',
            'mal' => 'malayalam',
            'pun' => 'punjabi',
          }[language_code_3_chars]
        end

      protected

        # Latex geometry magnifaction factor.
        def magnification
          1300
        end

        # Returns a complete latex document as string.
        # @param latex_body [String]
        # @param document_title_plain_text [String]
        # @param document_title_latex [String]
        # @return [String]
        def wrap_body_in_template(latex_body, document_title_plain_text, document_title_latex)
          # Assign l_vars not used in template
          git_repo = Repositext::Repository.new(@options[:source_filename])
          latest_commit = git_repo.latest_commit(@options[:source_filename])
          date_code = Repositext::Utils::FilenamePartExtractor.extract_date_code(
            @options[:source_filename]
          )
          language_code_3 = Repositext::Utils::FilenamePartExtractor.extract_language_code_3(
            @options[:source_filename]
          )
          # assign i_vars referenced in template file.
          @additional_footer_text = escape_latex_text(@options[:additional_footer_text])
          @body = latex_body
          @company_long_name = @options[:company_long_name]
          @company_phone_number = @options[:company_phone_number]
          @company_short_name = @options[:company_short_name]
          @company_web_address = @options[:company_web_address]
          @language_and_date_code = [language_code_3, date_code].upcase
          # Applies the settings for the first eagle indent and drop cap.
          @first_eagle = @options[:first_eagle]
          # Sets the starting page number.
          @first_page_number = @options[:first_page_number]
          @font_leading = @options[:font_leading]
          @font_name = @options[:font_name]
          @font_size = @options[:font_size]
          @footer_title = truncate_plain_text_title(
            @options[:footer_title_english], 43, 3
          ).unicode_upcase
          @has_id_page = @options[:has_id_page]
          @header_font_name = @options[:header_font_name]
          @header_text = compute_header_text_latex(
            @options[:header_text],
            @options[:header_footer_rules_present],
            @options[:language_code_3_chars]
          )
          @header_title = compute_header_title_latex(
            document_title_plain_text,
            document_title_latex,
            @options[:header_footer_rules_present],
            @options[:language_code_3_chars],
            @options[:truncated_header_title_length]
          )
          # Turns on hrules in title, header and footer.
          @header_footer_rules_present = @options[:header_footer_rules_present]
          # Sets the letter space for the headers.
          @header_letter_space = @options[:header_letter_space]
          @id_address_primary_latex_1 = @options[:id_address_primary_latex_1]
          @id_address_primary_latex_2 = @options[:id_address_primary_latex_2]
          @id_address_secondary_email = @options[:id_address_secondary_email]
          @id_address_secondary_latex_1 = @options[:id_address_secondary_latex_1]
          @id_address_secondary_latex_2 = @options[:id_address_secondary_latex_2]
          @id_address_secondary_latex_3 = @options[:id_address_secondary_latex_3]
          @id_copyright_year = @options[:id_copyright_year]
          @id_extra_language_info = @options[:id_extra_language_info]
          @id_paragraph_line_spacing = @options[:id_paragraph_line_spacing]
          @id_recording = @options[:id_recording]  if @options[:include_id_recording]
          @id_series = @options[:id_series]
          @id_title_1_font_size = @options[:id_title_1_font_size]
          @id_title_font_name = @options[:id_title_font_name]
          @id_write_to_primary = @options[:id_write_to_primary]
          @id_write_to_secondary = @options[:id_write_to_secondary]
          @include_meta_info = include_meta_info
          @is_primary_repo = @options[:is_primary_repo]
          @language_code_3 = language_code_3.upcase
          @language_name = @options[:language_name]
          @last_eagle_hspace = @options[:last_eagle_hspace]
          @latest_commit_hash = latest_commit.oid[0,8]
          @linebreaklocale = @options[:language_code_2_chars]
          @magnification = magnification
          @metadata_additional_keywords = @options[:metadata_additional_keywords]
          @metadata_author = @options[:metadata_author]
          @page_number_command = compute_page_number_command(
            @options[:header_footer_rules_present],
            @options[:language_code_3_chars]
          )
          @page_settings = page_settings_for_latex_geometry_package
          # Force foreign languages to use Excelsior for paragraph numbers.
          @paragraph_number_font_name = @options[:paragraph_number_font_name]
          @pdf_version = @options[:pdf_version]
          @piid = Repositext::Utils::FilenamePartExtractor.extract_product_identity_id(@options[:source_filename])
          @polyglossia_default_language = polyglossia_default_language(@options[:language_code_3_chars])
          @primary_font_name = @options[:primary_font_name]
          @pv_id = @options[:pv_id]
          @question1_indent = @options[:question1_indent]
          @question2_indent = @options[:question2_indent]
          @question3_indent = @options[:question3_indent]
          @song_leftskip = @options[:song_leftskip]
          @song_rightskip = @options[:song_rightskip]
          @text_left_to_right = @options[:text_left_to_right]
          @title_font_name = @options[:title_font_name]
          @title_font_size = @options[:title_font_size]
          @title_vspace = @options[:title_vspace] # space to be inserted above title to align with body text
          @use_cjk_package = ['chn','cnt'].include?(@options[:language_code_3_chars])
          # Sets the vbadness_penalty limit for veritcal justification. This is the maximum penalty allowed.
          @vbadness_penalty = @options[:vbadness_penalty]
          @version_control_page = if @options[:version_control_page]
            compute_version_control_page(git_repo, @options[:source_filename])
          else
            ''
          end
          @vspace_above_title1_required = @options[:vspace_above_title1_required]
          @vspace_below_title1_required = @options[:vspace_below_title1_required]

          # dependency boundary
          @meta_info = include_meta_info ? compute_meta_info(git_repo, latest_commit) : ''

          erb = ERB.new(latex_template, nil, '>')
          r = erb.result(binding)
          r
        end

        # Wraps header_text in latex markup (this is the non-title header text)
        # @param header_text [String]
        # @param header_footer_rules_present [Boolean]
        # @param language_code_3_chars [String]
        # @return [String]
        def compute_header_text_latex(header_text, header_footer_rules_present, language_code_3_chars)
          if header_footer_rules_present
            # italic, small caps and large font
            t = emulate_small_caps(
              escape_latex_text(header_text),
              @options[:font_name],
              %w[bold italic]
            )
            "\\textscale{#{ 0.909091 }}{\\textbf{\\textit{#{ t }}}}"
          else
            # regular, all caps and small font
            r = "\\textscale{#{ 0.7 }}{#{ escape_latex_text(header_text).unicode_upcase }}"
            if 'chn' == language_code_3_chars
              r = "\\textbf{#{ r }}"
            end
            r
          end
        end

        # Truncates and formats title so it can be used in page header.
        # Removes all formatting and line breaks except superscript on trailing
        # digits.
        # @param document_title_plain_text [String]
        # @param document_title_latex [String]
        # @param header_footer_rules_present [Boolean]
        # @param language_code_3_chars [String]
        # @param title_length_override [Integer, optional] will force
        #        title to be truncated to this many chars, ignoring word boundaries.
        # @return [String]
        def compute_header_title_latex(document_title_plain_text, document_title_latex, header_footer_rules_present, language_code_3_chars, title_length_override)
          if header_footer_rules_present # this means we're in primary repo
            # bold, italic, small caps and large font
            # NOTE: All titles are wrapped in <em> and .smcaps, so that will
            # take care of the italics and smallcaps.
            truncated = compute_truncated_title(
              document_title_plain_text,
              document_title_latex,
              title_length_override || 58,
              title_length_override ? 0 : 3,
            )
            # Replace title superscript params with header ones
            truncated.gsub!(
              [
                "{\\raisebox{#{ @options[:title_superscript_raise] }ex}",
                "{\\textscale{#{ @options[:title_superscript_scale] }}{",
              ].join,
              [
                "{\\raisebox{#{ @options[:header_superscript_raise] }ex}",
                "{\\textscale{#{ @options[:header_superscript_scale] }}{",
              ].join
            )
            "\\textscale{#{ 0.909091 }}{\\textbf{#{ truncated }}}"
          else
            # regular, all caps and small font
            # We use same method as for primary (with header_footer_rules_present),
            # except we pass plain text as document_title_latex.
            # This is so that we get newline removal and warnings on titles
            # that get truncated without a length override.
            truncated = compute_truncated_title(
              document_title_plain_text,
              document_title_plain_text, # Pass plain text as latex
              title_length_override || 54,
              title_length_override ? 0 : 3
            )
            r = "\\textscale{#{ 0.7 }}{#{ truncated.unicode_upcase }}"
            # re-apply superscript to any trailing digits
            if r =~ /\d+\}\z/
              r.gsub!(
                /\d+\}\z/,
                [
                  "{\\raisebox{#{ @options[:header_superscript_raise] }ex}",
                  "{\\textscale{#{ @options[:header_superscript_scale] }}{",
                  '\0',
                  "}}}",
                ].join
              )
            elsif r =~ /(?<=\d)[[:alpha:]]{1,2}(?=(\s|\z))/
              # re-apply superscript to letters after ordinal numbers, e.g., "3e partie"
              r.gsub!(
                /(?<=\d)[[:alpha:]]{1,2}(?=(\s|\z))/,
                [
                  "{\\raisebox{#{ @options[:header_superscript_raise] }ex}",
                  "{\\textscale{#{ @options[:header_superscript_scale] }}{",
                  '\0',
                  "}}}",
                ].join
              )
            end
            if 'chn' == language_code_3_chars
              r = "\\textbf{#{ r }}"
            end
            r
          end
        end

        # Computes a latex string for this document's meta info table
        # @param [Rugged::Repo] git_repo
        # @param [Rugged::Commit] latest_commit
        def compute_meta_info(git_repo, latest_commit)
          r = "\\begin{RtMetaInfo}\n"
          r << "\\begin{center}\n"
          r << "\\begin{tabular}{r l}\n"
          r << "\\multicolumn{2}{c}{Revision Information} \\\\\n"
          r << "\\hline\n"
          r << {
            'Date' => escape_latex_text(latest_commit.time.strftime('%b %d, %Y')),
            'Time' => escape_latex_text(latest_commit.time.strftime('%H:%M%P %z')),
            'Repository' => escape_latex_text(git_repo.name),
            'Branch' => escape_latex_text(git_repo.current_branch_name),
            'Latest commit' => escape_latex_text(latest_commit.oid[0,8]),
          }.map { |k,v| "#{ k } & #{ v } \\\\" }.join("\n")
          r << "\n\\end{tabular}\n"
          r << "\\end{center}\n"
          r << "\\end{RtMetaInfo}"
          r
        end

        # Computes the command to be used for page numbers in the page header.
        # @param header_footer_rules_present [Boolean]
        # @param language_code_3_chars [String]
        # @return [String]
        def compute_page_number_command(header_footer_rules_present, language_code_3_chars)
          if header_footer_rules_present
            # bold, italic, small caps and large font
            "\\textscale{#{ 0.909091 }}{\\textbf{\\textit{\\thepage}}}"
          else
            # regular
            r = "{\\thepage}"
            if 'chn' == language_code_3_chars
              r = "\\textbf{#{ r }}"
            end
            r
          end
        end

        # Returns a version of title that is guaranteed to be no longer than
        # max_len (after removing all latex markup) while maintaining valid
        # latex markup. Also any linebreaks are being removed
        #
        # This is how it works:
        #
        #     title_latex:     \emph{word} \emph{and some really long text to get truncation word \textscale{0.7}{word word word} word}
        #     plain text mask:                                                                                         xxxxxxxxx xxxxx
        #     title_plain_text:      word        and some really long text to get truncation word                 word word word  word
        #     trunc_title_pt:        word        and some really long text to get truncation word                 word…
        #     result:          \emph{word} \emph{and some really long text to get truncation word \textscale{0.7}{word…}}
        #
        # Three strings we work with:
        #   * title_plain_text (full plain text version of title)
        #   * title_latex (title with latex markup)
        #   * truncated_title_plain_text (truncated plain text version of title)
        #
        # Types of chars encountered:
        #   * latex_command
        #   * opening_brace
        #   * back_to_back_braces
        #   * closing_brace
        #   * matching_plain_text_char
        #   * other_char (e.g., latex function argument)
        #
        # State_variables:
        #   * plain_text_index (current position in plain_text_title)
        #   * brace_nesting_level (to balance braces)
        #   * reached_truncation_length (false until truncation length is reached)
        #
        # @param title_plain_text [String] the title in plain text format.
        # @param title_latex [String] the title in latex format.
        # @param max_len [Integer] maximum length of returned string.
        # @param min_length_of_last_word [Integer] minimum length of last word in returned string
        # @return [String]
        def compute_truncated_title(title_plain_text, title_latex, max_len, min_length_of_last_word)
          # Remove any line breaks
          l_title_latex = title_latex.gsub("\\linebreak\n", '')
          l_title_plain_text = title_plain_text.gsub("\n", '')

          # Nothing to do if l_title_plain_text is already short enough
          return l_title_latex  if l_title_plain_text.length <= max_len

          if 0 != min_length_of_last_word
            # A non-zero value indicates that there is no truncation override for this file.
            # We want to know of any titles that require truncation so that we can review
            # and set truncation point for best results.
            puts "Truncating text without having truncation override! Please add setting `pdf_export_truncated_header_title_length` to file's data.json file (under settings): #{ title_plain_text }".color(:red)
          end

          truncated_title_plain_text = truncate_plain_text_title(
            l_title_plain_text,
            max_len,
            min_length_of_last_word
          )

          brace_nesting_level = 0 # to keep track whether we're inside latex braces
          plain_text_index = 0 # position of plain_text we match
          reached_truncation_length = false # keep track of whether we've reached truncation point
          new_title_latex = ''

          open_brace_regex = /\{/
          back_to_back_braces_regex = /\}\{/
          closing_brace_regex = /\}/
          latex_command_regex = /\\[a-z]+/i
          latex_kerning_argument_regex = /\}?\{(?:-?[\d\.]+em|none)\}/

          s = StringScanner.new(l_title_latex)
          while !s.eos? do
            # check for various character types in descending specificity
            if (latex_cmd = s.scan(latex_command_regex))
              # latex command, capture, leave brace_nesting_level unchanged
              new_title_latex << latex_cmd
            elsif (latex_kerning_argument = s.scan(latex_kerning_argument_regex))
              # pos or neg kerning argument for RtSmCapsEmulation,
              # e.g., {-0.3em}, {0.2em}, or {none}
              # leave brace_nesting_level unchanged
              new_title_latex << latex_kerning_argument
            elsif (back_to_back_braces = s.scan(back_to_back_braces_regex))
              # back to back braces, capture, leave brace_nesting_level unchanged
              new_title_latex << back_to_back_braces
            elsif (open_brace = s.scan(open_brace_regex))
              # open brace, capture, increase nesting level
              new_title_latex << open_brace
              brace_nesting_level += 1
            elsif (closing_brace = s.scan(closing_brace_regex))
              # closing brace, capture, decrease nesting level
              raise "Invalid latex braces: #{ l_title_latex.inspect }"  if brace_nesting_level <= 0
              new_title_latex << closing_brace
              brace_nesting_level -= 1
            elsif (
              matching_plain_text_char = s.scan(
                Regexp.new(
                  Regexp.escape(
                    l_title_plain_text[plain_text_index]
                  ),
                  true # small caps emulation will capitalize letters in `s`
                )
              )
            )
              # match with current plain text character
              if !reached_truncation_length
                # Still room, use char from truncated string (so we get ellipsis)
                # We have to use whatever capitalization is in matching_plain_text_char
                # if it is the same letter as the corresponding one in
                # truncated_title_plain_text. Otherwise we use what's in
                # truncated_title_plain_text (e.g., the ellipsis)
                char_from_ttpt = truncated_title_plain_text[plain_text_index]
                if matching_plain_text_char.unicode_downcase == char_from_ttpt.unicode_downcase
                  # It's a matching letter, use capitalization from matching_plain_text_char
                  # so that we get correct small caps emulation (upper case)
                  new_title_latex << matching_plain_text_char
                else
                  # No letter match, this is probably an ellipsis
                  new_title_latex << truncated_title_plain_text[plain_text_index]
                end
              end
              plain_text_index += 1
              # detect whether we've reached truncation length
              if truncated_title_plain_text[plain_text_index].nil?
                reached_truncation_length = true
              end
            else
              # other character, capture
              new_title_latex << s.getch
            end
            if brace_nesting_level <= 0 && reached_truncation_length
              # We've reached the end of truncated plain_text string,
              # we're not in a latex command, and all latex braces have been
              # closed.
              s.terminate
            end
          end
          new_title_latex
        end

        # @param plain_text_title [String]
        # @param max_len [Integer] maximum length of returned string.
        # @param min_length_of_last_word [Integer] minimum length of last word
        #        in returned string. If set to zero, word boundaries are ignored.
        # @return [String]
        def truncate_plain_text_title(plain_text_title, max_len, min_length_of_last_word)
          opts = if 0 == min_length_of_last_word
            # Ignoring word boundaries
            {
              omission: '…',
            }
          else
            # Truncate at word boundary
            {
              separator: /(?<=[[:alnum:]]{#{ min_length_of_last_word }})\s/,
              omission: '…',
            }
          end
          plain_text_title.truncate(max_len, opts)
        end

        # Returns a list of commits and commit messages for the exported file.
        # To be used as version_control_page in the exported pdf
        # @param [Rugged::Repo] git_repo
        # @param [String] source_file_path the source file's path
        # @return [String] the version control page as latex string
        def compute_version_control_page(git_repo, source_file_path)
          max_number_of_commits = 20
          recent_commits_for_source_file_path = git_repo.latest_commits_local(
            source_file_path,
            max_number_of_commits
          ).reverse # reverse to get oldest first

          # header
          vcp = "\\clearpage\n"
          vcp << "\\begin{english}"
          vcp << "\\begin{RtSubTitle}\nVersion Control Info\n\\end{RtSubTitle}\n"
          vcp << "\\relscale{0.66}\n"
          # commits table
          vcp << "\\begin{tabular}{ | p{0.4in} | p{0.7in} | p{0.5in} | p{1.9in} |}\n"
          vcp << "\\hline\n"
          vcp << "\\textbf{Commit} & \\textbf{Author} & \\textbf{Date} & \\textbf{Commit message} \\\\ \n"
          vcp << "\\hline\n"
          recent_commits_for_source_file_path.each do |ca|
            vcp << [
              escape_latex_text(ca[:commit_hash]),
              escape_latex_text(ca[:author]),
              escape_latex_text(ca[:date]),
              escape_latex_text(ca[:message]),
            ].join(' & ') # table cells
            vcp << "\\\\ \n" # end of table row
            vcp << "\\hline\n"
          end
          vcp << "\\end{tabular}\n"
          # footer
          source_file_name = source_file_path.split('/').last(3).join('/')
          vcp << [
            "\n\n \\noindent\\caption{The table above lists the #{ max_number_of_commits } ",
            "most recent git commits that affected the file ",
            "#{ escape_latex_text(source_file_name.inspect) }.}\n\n",
          ].join
          vcp << "\\end{english}"
          vcp
        end

        # Returns page settings as string that can be passed to latex
        # geometry package. Example:
        # "paperwidth=8.5in, paperheight=11in, inner=1in, outer=1in, top=1in, bottom=1.5in"
        def page_settings_for_latex_geometry_package
          ps = page_settings(@options[:page_settings_key])
          if !ps.is_a?(Hash) || ps.first.last.is_a?(Hash)
            raise(ArgumentError.new("Invalid options[:page_settings_key]: #{ @options[:page_settings_key].inspect }, returns #{ ps.inspect }"))
          end
          ps.map { |k,v| %(#{ k }=#{ v }) }.join(', ')
        end

      end
    end
  end
end
