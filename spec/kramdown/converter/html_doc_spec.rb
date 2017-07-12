require_relative '../../helper'

module Kramdown
  module Converter
    describe HtmlDoc do

      it 'computes the html title and body and inserts them into the template' do
        template_io = StringIO.new(
          %(<html>\n  <head><title><%= @title %></title></head>\n  <body><%= @body %></body></html>),
          'r'
        )
        r = Document.new(
          "# The Title\n\nThe Body",
          {
            :input => 'KramdownRepositext',
            :template_file => template_io
          }
        ).to_html_doc
        r.must_equal %(
          <html>
            <head><title>The Title
          </title></head>
            <body><h1 id=\"the-title\">The Title</h1>

          <p>The Body</p>
          </body></html>
        ).strip.gsub(/          /, '')
      end

      describe 'compute_title' do

        [
          ["# The Title\n\nThe Body", "The Title\n"],
          ["# *The* Title\n\nThe Body", "The Title\n"],
        ].each_with_index do |(doc, exp), idx|
          it "uses the first :header element (Example #{ idx + 1 }" do
            template_io = StringIO.new('<%= @title %>', 'r')
            r = Document.new(
              doc,
              {
                :input => 'KramdownRepositext',
                :template_file => template_io
              }
            ).to_html_doc
            r.must_equal exp
          end
        end

        it "falls back to 'No Title' if no header is present" do
          template_io = StringIO.new('<%= @title %>', 'r')
          r = Document.new(
            "The Body",
            {
              :input => 'KramdownRepositext',
              :template_file => template_io
            }
          ).to_html_doc
          r.must_equal %(No Title)
        end

      end

    end
  end
end
