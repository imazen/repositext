require_relative '../../../helper'

module Kramdown
  module Parser
    describe KramdownRepositext do
      describe 'Unsupported block parsers' do

        [
          [:abbrev_definition, "This is some text.\n*[is some]: Yes it is", %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is some text.\\n*[is some]: Yes it is\"\n)],
          [:block_html, "This is a para.\n<div>\nSomething in here.\n</div>\nOther para.", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is a para.\\n<div>\\nSomething in here.\\n</div>\\nOther para.\"\n"],
          [:block_math, "This is a para.\n$$ \text{LaTeX} \lambda_5 $$", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is a para.\\n$$ \\text{LaTeX} lambda_5 $$\"\n"],
          [:blockquote, "> This is a quote", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"> This is a quote\"\n"],
          [:codeblock, "paragraph\n\n    code", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"paragraph\"\n   - :blank - {:location=>3} - \"\\n\"\n   - :text - {:location=>1} - \"    code\\n\"\n"],
          [:codeblock_fenced, "~~~~~~~~\nHere comes some code.\n~~~~~~~~", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"~~~~~~~~\\nHere comes some code.\\n~~~~~~~~\"\n"],
          [:definition_list, "kram\n: down", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"kram\\n: down\"\n"],
          [:eob_marker, "\n\n^\n\n", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :blank - {:location=>3} - \"\\n\\n\"\n   - :p - {:location=>3}\n     - :text - {:location=>3} - \"^\"\n   - :blank - {:location=>5} - \"\\n\"\n"],
          [:footnote_definition, "", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :blank - {:location=>2} - \"\\n\"\n"],
          [:link_definition, "", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :blank - {:location=>2} - \"\\n\"\n"],
          [:list, "* This is a simple list item\n* Followed by another", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"* This is a simple list item\\n* Followed by another\"\n"],
          [:table, "|cell1|cell2|\n|cell3|cell4|", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"|cell1|cell2|\\n|cell3|cell4|\"\n"]
        ].each do |parser_attrs|
          parser_name, kramdown_in, xpect = parser_attrs
          it "doesn't parse #{ parser_name }" do
            doc = Kramdown::Document.new(kramdown_in, { :input => 'KramdownRepositext' })
            doc.root.inspect_tree.must_equal xpect
          end
        end

      end
    end
  end
end
