# -*- coding: utf-8 -*-

# Converts kramdown to complete HTML file, inserting the HTML body into a template.
# Writes output to an IO object (File or StringIO).
# Computes title from first :header element.
module Kramdown
  module Converter
    class HtmlDoc < Base

      # Create an HtmlDoc converter with the given options.
      # @param[Kramdown::Element] root
      # @param[Hash, optional] options
      def initialize(root, options = {})
        super
        # NOTE: kramdown initializes all options with default values. So
        # :output_file and :template_file are initialized to Nil. This breaks
        # @options = { <defaults> }.merge(options), so I have to set them like below.
        options[:output_file] ||= File.new("html_output.html", 'w')
        options[:template_file] ||= File.new(
          File.expand_path("../../../../templates/html.erb", __FILE__),
          'r'
        )
        @options = options
      end

      # Writes an HTML file to IO (using @options[:output_file]).
      # @param[Kramdown::Element] root the kramdown root element
      def convert(root)
        html_title = compute_title(root)
        html_body = compute_body(root)
        erb_template = options[:template_file].read
        write_file(html_title, html_body, erb_template, options[:output_file])
      end

    protected

      # Computes a title.
      # Walks the tree, uses the inner text of the first header it finds.
      # Uses fall_back if no header with inner text is found.
      # @param[Kramdown::Element] el
      # @param[String, optional] fall_back
      # @return[String] the title
      def compute_title(el, fall_back = 'No Title')
        # first test if el is of type :header and return text
        if :header == el.type
          r = ::Kramdown::Document.new(
            el.options[:raw_text], { :input => 'kramdown' }
          ).to_plain_text
          return r  if '' != r
        end
        # recurse over children
        title_from_header = el.children.map { |e| compute_title(e, fall_back) }.compact.first
        # We're back in the :root element, return title value
        if :root == el.type && !title_from_header
          # No :header was found, use fall_back.
          fall_back
        else
          # Inner text from :header
          title_from_header
        end
      end

      # Computes the HTML body from root.
      # @param[Kramdown::Element] root
      # @return[String] the title
      def compute_body(root)
        html_body, _warnings = ::Kramdown::Converter::Html.convert(root, @options)
        html_body
      end

      # Write HTML to file on disk
      # @param[String] html_title Will be inserted into <title> tag.
      # @param[String] html_body Will be inserted into template's <body> tag.
      # @param[String] erb_template the erb template
      # @param[IO] output_file an IO object to write to
      def write_file(html_title, html_body, erb_template, output_file)
        # assign i_vars referenced in template file
        @title = html_title
        @body = html_body

        erb = ERB.new(erb_template)
        output_file.write(erb.result(binding))
      end

    end
  end
end
