# -*- coding: utf-8 -*-
# TODO: use kramdown's templating
module Kramdown
  module Converter
    class LatexRepositext
      module DocumentMixin

        # Create an HtmlDoc converter with the given options.
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
            inner: 1,
            outer: 1,
            top: 0.7,
            bottom: 1.2,
          }
        end

        # This factor will be applied to all font-metrics to enable enlarged
        # PDFs.
        def size_scale_factor
          1.25
        end

        def include_meta_info
          true
        end

      protected

        # Returns a complete latex document as string.
        # @param[String] latex_body
        # @param[String] document_title
        # @return[String]
        def wrap_body_in_template(latex_body, document_title)
          # assign i_vars referenced in template file
          @additional_footer_text = @options[:additional_footer_text]
          @body = latex_body
          @date_code = @options[:source_filename].split('/')
                                                 .last
                                                 .match(/[[:alpha:]]{3}\d{2}-\d{4}[[:alpha:]]?/)
                                                 .to_s
                                                 .capitalize
          @git_repo = Repositext::Repository.new
          @include_meta_info = include_meta_info
          @font_name = @options[:font_name]
          @latest_commit = @git_repo.latest_commit(@options[:source_filename])
          @latest_commit_hash = @latest_commit.oid[0,8]
          @scale_factor = size_scale_factor
          @title = document_title
          @title_font_name = @options[:title_font_name]
          @truncated_title_footer = compute_truncated_title(document_title, 45, 3)
          @truncated_title_header = compute_truncated_title(document_title, 70, 3)
          @page_settings = page_settings_for_latex_geometry_package
          # dependency boundary
          @meta_info = include_meta_info ? compute_meta_info(@git_repo, @latest_commit) : ''

          erb = ERB.new(latex_template)
          r = erb.result(binding)
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
            'Date' => latest_commit.time.strftime('%b %d, %Y'),
            'Time' => latest_commit.time.strftime('%H:%M%P %z'),
            'Repository' => git_repo.name,
            'Branch' => git_repo.current_branch_name,
            'Latest commit' => latest_commit.oid[0,8],
          }.map { |k,v| "#{ k } & #{ v } \\\\" }.join("\n")
          r << "\n\\end{tabular}\n"
          r << "\\end{center}\n"
          r << "\\end{RtMetaInfo}"
          r
        end

        # Returns a version of title that is guaranteed to be no longer than
        # max_len
        # @param[String] title the title without any latex commands
        # @param[Integer] max_len maximum length of returned string
        # @param[Integer] min_length_of_last_word minimum length of last word in returned string
        def compute_truncated_title(title, max_len, min_length_of_last_word)
          t = title.truncate(max_len, separator: /(?<=[[:alpha:]]{#{min_length_of_last_word}})\s/)
          t = ::Kramdown::Converter::LatexRepositext.emulate_small_caps(t)
          t
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
