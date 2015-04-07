# -*- coding: utf-8 -*-
# TODO: use kramdown's templating
module Kramdown
  module Converter
    class LatexRepositext
      module DocumentMixin

        # Create an LatexRepositext Document converter with the given options.
        # @param[Kramdown::Element] root
        # @param[Hash, optional] options
        def initialize(root, options = {})
          super
          # NOTE: kramdown initializes all options with default values. So
          # :template_file is initialized to Nil. This breaks
          # @options = { <defaults> }.merge(options), so I have to set them like below.
          # TODO: when unifying class API, move files out of the classes into caller?
          # options[:template_file] ||= latex_template_path
          @options = options
        end

        # Returns latex_template as ERB string
        def latex_template
          @latex_template ||= File.new(
            File.expand_path("../../../../../templates/latex_for_pdf.erb", __FILE__),
            'r'
          ).read
        end

        # Configure page settings. All values are in inches
        def page_settings(key = nil)
          page_settings = {
            paperwidth: 8.5,
            paperheight: 11,
            inner: 1.304655,
            outer: 1.345345,
            top: 0.65065,
            bottom: 0.27981,
            headsep: 0.1621,
            footskip: 0.38965,
          }
        end

        # This factor will be applied to all font-metrics to enable enlarged
        # PDFs.
        def size_scale_factor
          1.3
        end

        def include_meta_info
          true
        end

      protected

        # Returns a complete latex document as string.
        # @param latex_body [String]
        # @param document_title_plain_text [String]
        # @param document_title_latex [String]
        # @return[String]
        def wrap_body_in_template(latex_body, document_title_plain_text, document_title_latex)
          # Assign l_vars not used in template
          date_code = @options[:source_filename].split('/')
                                                 .last
                                                 .match(/[[:alpha:]]{3}\d{2}-\d{4}[[:alpha:]]?/)
                                                 .to_s
          git_repo = Repositext::Repository.new
          latest_commit = git_repo.latest_commit(@options[:source_filename])
          # assign i_vars referenced in template file
          @additional_footer_text = escape_latex_text(@options[:additional_footer_text])
          @body = latex_body
          @date_code = date_code.capitalize
          @font_leading = @options[:font_leading_override] || 11.8
          @font_name = @options[:font_name_override] || (@options[:is_primary_repo] ? 'V-Calisto-St' : 'V-Excelsior LT Std')
          @font_size = @options[:font_size_override] || 11
          @header_text = compute_header_text_latex(
            @options[:header_text],
            @options[:is_primary_repo],
            @options[:language_code_3_chars]
          )
          @header_title = compute_header_title_latex(
            document_title_plain_text,
            document_title_latex,
            @options[:is_primary_repo],
            @options[:language_code_3_chars]
          )
          @include_meta_info = include_meta_info
          @is_primary_repo = @options[:is_primary_repo]
          @latest_commit_hash = latest_commit.oid[0,8]
          @page_number_command = compute_page_number_command(
            @options[:is_primary_repo],
            @options[:language_code_3_chars]
          )
          @page_settings = page_settings_for_latex_geometry_package
          @paragraph_number_font_name = @options[:font_name_override] ? 'V-Excelsior LT Std' : @font_name
          @primary_font_name = 'V-Calisto-St'
          @scale_factor = size_scale_factor
          @title_font_name = @options[:font_name_override] || 'V-Calisto-St'
          @truncated_title_footer = compute_truncated_title(
            document_title_plain_text, document_title_latex, 45, 3
          )
          @use_cjk_package = ['chn'].include?(@options[:language_code_3_chars])
          @version_control_page = if @options[:version_control_page]
            compute_version_control_page(git_repo, @options[:source_filename])
          else
            ''
          end
          # dependency boundary
          @meta_info = include_meta_info ? compute_meta_info(git_repo, latest_commit) : ''

          erb = ERB.new(latex_template)
          r = erb.result(binding)
          r
        end

        # @param[String] header_text
        # @param[Boolean] is_primary_repo
        def compute_header_text_latex(header_text, is_primary_repo, language_code_3_chars)
          if is_primary_repo
            # italic, small caps and large font
            t = ::Kramdown::Converter::LatexRepositext.emulate_small_caps(
              escape_latex_text(header_text)
            )
            "\\textscale{#{ 0.909091 * size_scale_factor }}{\\textbf{\\textit{#{ t }}}}"
          else
            # regular, all caps and small font
            r = "\\textscale{#{ 0.7 * size_scale_factor }}{#{ UnicodeUtils.upcase(escape_latex_text(header_text)) }}"
            if 'chn' == language_code_3_chars
              r = "\\textbf{#{ r }}"
            end
            r
          end
        end

        # @param document_title_plain_text [String]
        # @param document_title_latex [String]
        # @param is_primary_repo [Boolean]
        # @param language_code_3_chars [String]
        # @return [String]
        def compute_header_title_latex(document_title_plain_text, document_title_latex, is_primary_repo, language_code_3_chars)
          if is_primary_repo
            # bold, italic, small caps and large font
            # NOTE: All titles are wrapped in <em>, so that will take care of the italics part.
            # That means we don't need to add it here.
            truncated = compute_truncated_title(document_title_plain_text, document_title_latex, 63, 3)
            small_caps = ::Kramdown::Converter::LatexRepositext.emulate_small_caps(truncated)
            "\\textscale{#{ 0.909091 * size_scale_factor }}{\\textbf{#{ small_caps }}}"
          else
            # regular, all caps and small font
            truncated = compute_truncated_title(document_title_plain_text, document_title_latex, 54, 3)
            # NOTE: This is really screwed up, but it works:
            # For foreign we don't want italic. However the title is wrapped in <em>.
            # The italic is neutralized because the upcase command converts
            # "\emph" => "\EMPH" which is not recognized by latex, so no italics is applied.
            # So for the time being I'll leave it as is.
            r = "\\textscale{#{ 0.7 * size_scale_factor }}{#{ UnicodeUtils.upcase(truncated) }}"
            if 'chn' == language_code_3_chars
              r = "\\textbf{#{ r }}"
            end
            r
          end
        end

        # Computes a latex string for this document's meta info table
        # @param[Rugged::Repo] git_repo
        # @param[Rugged::Commit] latest_commit
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

        def compute_page_number_command(is_primary_repo, language_code_3_chars)
          if is_primary_repo
            # bold, italic, small caps and large font
            "\\textscale{#{ 0.909091 * size_scale_factor }}{\\textbf{\\textit{\\thepage}}}"
          else
            # regular
            r = "\\textscale{#{ size_scale_factor }}{\\thepage}"
            if 'chn' == language_code_3_chars
              r = "\\textbf{#{ r }}"
            end
            r
          end
        end

        # Returns a version of title that is guaranteed to be no longer than
        # max_len (after removing all latex markup) while maintaining valid
        # latex markup.
        #
        # This is how it works:
        # title_latex:     \emph{word} \emph{and some really long text to get truncation word \textscale{0.7}{word word word} word}
        # plain text mask:                                                                                         xxxxxxxxx xxxxx
        # title_plain_text:      word        and some really long text to get truncation word                 word word word  word
        # trunc_title_pt:        word        and some really long text to get truncation word                 word…
        # result:          \emph{word} \emph{and some really long text to get truncation word \textscale{0.7}{word…}}
        #
        # Three strings we work with:
        #   * title_plain_text (full plain text version of title)
        #   * title_latex (title with latex markup)
        #   * truncated_title_plain_text (truncated plain text version of title)
        # Types of chars encountered:
        #   * latex_command
        #   * opening_brace
        #   * back_to_back_braces
        #   * closing_brace
        #   * matching_plain_text_char
        #   * other_char (e.g., latex function argument)
        # State_variables:
        #   * plain_text_index (current position in plain_text_title)
        #   * brace_nesting_level (to balance braces)
        #   * reached_truncation_length (false until truncation length is reached)
        #
        # @param title_plain_text [String] the title in plain text format.
        # @param title_latex [String] the title in latex format.
        # @param max_len [Integer] maximum length of returned string.
        # @param min_length_of_last_word [Integer] minimum length of last word in returned string
        def compute_truncated_title(title_plain_text, title_latex, max_len, min_length_of_last_word)
          # Nothing to do if title_plain_text is already short enough
          return title_latex  if title_plain_text.length <= max_len

          truncated_title_plain_text = title_plain_text.truncate(
            max_len,
            separator: /(?<=[[:alpha:]]{#{ min_length_of_last_word }})\s/,
            omission: '…',
          )

          brace_nesting_level = 0 # to keep track whether we're inside latex braces
          plain_text_index = 0 # position of plain_text we match
          reached_truncation_length = false # keep track of whether we've reached truncation point
          new_title_latex = ''

          open_brace_regex = /\{/
          back_to_back_braces_regex = /\}\{/
          closing_brace_regex = /\}/
          latex_command_regex = /\\[a-z]+/i

          s = StringScanner.new(title_latex)
          while !s.eos? do
            # check for various character types in descending specificity
            if (latex_cmd = s.scan(latex_command_regex))
              # latex command, capture, leave brace_nesting_level unchanged
              new_title_latex << latex_cmd
            elsif (back_to_back_braces = s.scan(back_to_back_braces_regex))
              # back to back braces, capture, leave brace_nesting_level unchanged
              new_title_latex << back_to_back_braces
            elsif (open_brace = s.scan(open_brace_regex))
              # open brace, capture, increase nesting level
              new_title_latex << open_brace
              brace_nesting_level += 1
            elsif (closing_brace = s.scan(closing_brace_regex))
              # closing brace, capture, decrease nesting level
              raise "Invalid latex braces: #{ title_latex.inspect }"  if brace_nesting_level <= 0
              new_title_latex << closing_brace
              brace_nesting_level -= 1
            elsif (
              matching_plain_text_char = s.scan(
                Regexp.new(
                  Regexp.escape(
                    title_plain_text[plain_text_index]
                  )
                )
              )
            )
              # match with current plain text character
              if !reached_truncation_length
                # still room, use char from truncated string (so we get ellipsis)
                new_title_latex << truncated_title_plain_text[plain_text_index]
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

        # Returns a list of commits and commit messages for the exported file.
        # To be used as version_control_page in the exported pdf
        # @param[Rugged::Repo] git_repo
        # @param[String] source_file_path the source file's path
        # @return[String] the version control page as latex string
        def compute_version_control_page(git_repo, source_file_path)
          max_number_of_commits = 20
          recent_commits_for_source_file_path = git_repo.latest_commits_local(
            source_file_path,
            max_number_of_commits
          ).reverse # reverse to get oldest first

          # header
          vcp = "\\clearpage\n"
          vcp << "\\begin{RtSubTitle}\nVersion Control Info\n\\end{RtSubTitle}\n"
          vcp << "\\relscale{0.66}\n"
          # commits table
          vcp << "\\begin{tabular}{ | l | l | l | p{9cm} |}\n"
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
          ps.map { |k,v| %(#{ k }=#{ v }in) }.join(', ')
        end

      end
    end
  end
end
