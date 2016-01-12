# -*- coding: utf-8 -*-

# Converts kramdown to complete HTML file, inserting the HTML body into a template.
# Writes output to an IO object (File or StringIO).
# Computes title from first :header element.

# TODO: use kramdown's templating

module Kramdown
  module Converter
    class HtmlDoc < Base

      # Create an HtmlDoc converter with the given options.
      # @param [Kramdown::Element] root
      # @param [Hash, optional] options
      def initialize(root, options = {})
        super
        # NOTE: kramdown initializes all options with default values. So
        # :output_file and :template_file are initialized to Nil. This breaks
        # @options = { <defaults> }.merge(options), so I have to set them like below.
        # TODO: when unifying class API, move files out of the classes into caller?
        options[:output_file] ||= File.new("html_output.html", 'w')
        options[:template_file] ||= File.new(
          File.expand_path("../../../../templates/html.erb", __FILE__),
          'r'
        )
        @options = options
      end

      # Override this method to change the HTML converter to be used
      def html_converter_class
        ::Kramdown::Converter::Html
      end

      # Returns an HTML string.
      # @param [Kramdown::Element] root the kramdown root element
      def convert(root)
        html_title = compute_title(root)
        html_body = compute_body(root)
        erb_template = options[:template_file].read
        render_output(html_title, html_body, erb_template)
      end

    protected

      # Computes a title.
      # Walks the tree, uses the inner text of the first header it finds.
      # Uses fall_back if no header with inner text is found.
      # @param [Kramdown::Element] el
      # @param [String, optional] fall_back
      # @return [String] the title
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
      # @param [Kramdown::Element] root
      # @return [String] the title
      def compute_body(root)
        html_body, _warnings = html_converter_class.convert(root, @options)
        html_body
      end

      # Returns an HTML string
      # @param [String] html_title Will be inserted into <title> tag.
      # @param [String] html_body Will be inserted into template's <body> tag.
      # @param [String] erb_template the erb template
      def render_output(html_title, html_body, erb_template)
        # assign i_vars referenced in template file
        @title = html_title
        @body = html_body

        erb = ERB.new(erb_template)
        erb.result(binding)
      end

    end
  end
end
