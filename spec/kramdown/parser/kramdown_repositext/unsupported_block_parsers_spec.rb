require 'helper'

describe 'Unsupported block parsers' do

  [
    [:abbrev_definition, "This is some text.\n*[is some]: Yes it is", %(<p>This is some text.\n*[is some]: Yes it is</p>\n)],
    [:block_html, "This is a para.\n<div>\nSomething in here.\n</div>\nOther para.", "<p>This is a para.\n&lt;div&gt;\nSomething in here.\n&lt;/div&gt;\nOther para.</p>\n"],
    [:block_math, "This is a para.\n$$ \text{LaTeX} \lambda_5 $$", "<p>This is a para.\n$$ \text{LaTeX} \lambda_5 $$</p>\n"],
    [:blockquote, "> This is a quote", "<p>&gt; This is a quote</p>\n"],
    [:codeblock, "paragraph\n\n    code", "<p>paragraph</p>\n\n    code\n"],
    [:codeblock_fenced, "~~~~~~~~\nHere comes some code.\n~~~~~~~~", "<p>~~~~~~~~\nHere comes some code.\n~~~~~~~~</p>\n"],
    [:definition_list, "kram\n: down", "<p>kram\n: down</p>\n"],
    [:eob_marker, "\n\n^\n\n", "\n<p>^</p>\n\n"],
    [:footnote_definition, "", "\n"], # WIP
    [:link_definition, "", "\n"], # WIP
    [:list, "* This is a simple list item\n* Followed by another", "<p>* This is a simple list item\n* Followed by another</p>\n"],
    [:table, "|cell1|cell2|\n|cell3|cell4|", "<p>|cell1|cell2|\n|cell3|cell4|</p>\n"]
  ].each do |parser_attrs|
    parser_name, kramdown_in, html_out = parser_attrs
    it "doesn't parse #{ parser_name }" do
      doc = Kramdown::Document.new(kramdown_in, { :input => 'KramdownRepositext' })
      doc.to_html.must_equal html_out
    end
  end

end
