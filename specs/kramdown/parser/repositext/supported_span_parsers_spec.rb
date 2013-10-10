require 'helper'

describe 'Supported span parsers' do

  [
    [:emphasis, "This *is* so **hard**.", "<p>This <em>is</em> so <strong>hard</strong>.</p>\n"],
    [:gap_mark, "%", "<p><span class=\"sync-mark-b\"></span></p>\n"],
    [:span_extensions, "This is a {::comment}simple{:/} paragraph.", "<p>This is a <!-- simple --> paragraph.</p>\n"],
    [:subtitle_mark, "@", "<p><span class=\"sync-mark-a\"></span></p>\n"]
  ].each do |parser_attrs|
    parser_name, kramdown_in, html_out = parser_attrs
    it "parses #{ parser_name }" do
      doc = Kramdown::Document.new(kramdown_in, { :input => :repositext })
      doc.to_html.must_equal html_out
    end
  end

end
