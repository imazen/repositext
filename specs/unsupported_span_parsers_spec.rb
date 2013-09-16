require_relative 'helper'

describe 'Unsupported span parsers' do

  [
    [:autolink, "This should be a <http://www.example.com/> link.", "<p>This should be a &lt;http://www.example.com/&gt; link.</p>\n"],
    [:codespan, "This is `a` simple span.", "<p>This is `a` simple span.</p>\n"],
    [:footnote_marker, "This is some *ref.[^fn]\n\n[^fn]: Some foot note text", "<p>This is some *ref.[^fn]</p>\n\n<p>[^fn]: Some foot note text</p>\n"],
    [:html_entity, "", "\n"], # WIP
    [:inline_math, "This is $$\lambda_\alpha > 5$$ some math.", "<p>This is $$lambda_\alpha &gt; 5$$ some math.</p>\n"],
    [:line_break, "This is a line\nwith a line break.", "<p>This is a line\nwith a line break.</p>\n"],
    [:link, "simple [URL]()", "<p>simple [URL]()</p>\n"],
    [:smart_quotes, %("_Hurrah!_"), "<p>\"<em>Hurrah!</em>\"</p>\n"],
    [:span_html, %(<a href="test">title</a> is a title.), "<p>&lt;a href=\"test\"&gt;title&lt;/a&gt; is a title.</p>\n"],
    [:typographic_syms, "This is... something---this too--!", "<p>This is... something---this too--!</p>\n"]
  ].each do |parser_attrs|
    parser_name, kramdown_in, html_out = parser_attrs
    it "doesn't parse #{ parser_name }" do
      doc = Kramdown::Document.new(
        kramdown_in,
        { :input => :repositext, :disable_subdoc => true }
      )
      doc.to_html.must_equal html_out
   end
  end

end
