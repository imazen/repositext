require 'helper'

describe 'Supported block parsers' do

  [
    [:atx_header, "# header", "<h1 id=\"header\">header</h1>\n"],
    [:blank_line, "\n\n\n", "\n"],
    [:block_extensions, "{::comment}\nThis is a comment {:/}which is {:/comment} ignored.\n{:/comment}", "<!-- This is a comment {:/}which is {:/comment} ignored. -->\n"],
    [:record_mark, "^^^", "<div>\n</div>\n"],
    [:horizontal_rule, "***", "<hr />\n"],
    [:paragraph, "This is just a normal paragraph.", "<p>This is just a normal paragraph.</p>\n"],
    [:setext_header, "header\n====", "<h1 id=\"header\">header</h1>\n"]
  ].each do |parser_attrs|
    parser_name, kramdown_in, html_out = parser_attrs
    it "parses #{ parser_name }" do
      doc = Kramdown::Document.new(kramdown_in, { :input => :repositext })
      doc.to_html.must_equal html_out
    end
  end

end
