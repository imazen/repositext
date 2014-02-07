require_relative '../../helper'

describe Kramdown::Converter::HtmlDoc do

  it 'computes the html title and body and inserts them into the template' do
    template_io = StringIO.new(
      %(<html>\n  <head><title><%= @title %></title></head>\n  <body><%= @body %></body></html>),
      'r'
    )
    output_io = StringIO.new('', 'w+')
    Kramdown::Document.new(
      "# The Title\n\nThe Body",
      {
        :output_file => output_io,
        :input => 'KramdownRepositext',
        :template_file => template_io
      }
    ).to_html_doc
    output_io.rewind
    output_io.read.must_equal %(
      <html>
        <head><title>The Title</title></head>
        <body><h1 id=\"the-title\">The Title</h1>

      <p>The Body</p>
      </body></html>
    ).strip.gsub(/      /, '')
  end

  describe 'compute_title' do

    [
      ["# The Title\n\nThe Body", 'The Title'],
      ["# *The* Title\n\nThe Body", 'The Title'],
    ].each_with_index do |(doc, exp), idx|
      it "uses the first :header element (Example #{ idx + 1 }" do
        template_io = StringIO.new('<%= @title %>', 'r')
        output_io = StringIO.new('', 'w+')
        Kramdown::Document.new(
          doc,
          {
            :output_file => output_io,
            :input => 'KramdownRepositext',
            :template_file => template_io
          }
        ).to_html_doc
        output_io.rewind
        output_io.read.must_equal exp
      end
    end

    it "falls back to 'No Title' if no header is present" do
      template_io = StringIO.new('<%= @title %>', 'r')
      output_io = StringIO.new('', 'w+')
      Kramdown::Document.new(
        "The Body",
        {
          :output_file => output_io,
          :input => 'KramdownRepositext',
          :template_file => template_io
        }
      ).to_html_doc
      output_io.rewind
      output_io.read.must_equal %(No Title)
    end

  end

end
