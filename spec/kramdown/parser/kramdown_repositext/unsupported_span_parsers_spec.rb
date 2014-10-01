require_relative '../../../helper'

module Kramdown
  module Parser
    class KramdownRepositext
      describe 'Unsupported span parsers' do

        [
          [:autolink, "This should be a <http://www.example.com/> link.", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This should be a <http://www.example.com/> link.\"\n"],
          [:codespan, "This is `a` simple span.", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is `a` simple span.\"\n"],
          [:footnote_marker, "This is some *ref.[^fn]\n\n[^fn]: Some foot note text", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is some *ref.[^fn]\"\n   - :blank - {:location=>3} - \"\\n\"\n   - :p - {:location=>3}\n     - :text - {:location=>3} - \"[^fn]: Some foot note text\"\n"],
          [:inline_math, "This is $$\lambda_\alpha > 5$$ some math.", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is $$lambda_\\alpha > 5$$ some math.\"\n"],
          [:line_break, "This is a line\nwith a line break.", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is a line\\nwith a line break.\"\n"],
          [:link, "simple [URL]()", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"simple [URL]()\"\n"],
          [:smart_quotes, %("_Hurrah!_"), " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"\\\"\"\n     - :em - {:location=>1}\n       - :text - {:location=>1} - \"Hurrah!\"\n     - :text - {:location=>1} - \"\\\"\"\n"],
          [:span_html, %(<a href="test">title</a> is a title.), " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"<a href=\\\"test\\\">title</a> is a title.\"\n"],
          [:typographic_syms, %(This is... something---this too--! << keep these >> and leave the 'single' and "double" quotes as is.), " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is... something---this too--! << kee [...]  the 'single' and \\\"double\\\" quotes as is.\"\n"]
        ].each do |parser_attrs|
          parser_name, kramdown_in, xpect = parser_attrs
          it "doesn't parse #{ parser_name }" do
            doc = Document.new(kramdown_in, { :input => 'KramdownRepositext' })
            doc.root.inspect_tree.must_equal xpect
         end
        end

      end
    end
  end
end
