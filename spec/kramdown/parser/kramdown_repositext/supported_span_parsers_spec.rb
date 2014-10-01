require_relative '../../../helper'

module Kramdown
  module Parser
    class KramdownRepositext
      describe 'Supported span parsers' do

        [
          [:emphasis, "This *is* so **hard**.", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This \"\n     - :em - {:location=>1}\n       - :text - {:location=>1} - \"is\"\n     - :text - {:location=>1} - \" so \"\n     - :strong - {:location=>1}\n       - :text - {:location=>1} - \"hard\"\n     - :text - {:location=>1} - \".\"\n"],
          [:html_entity, "&#38; - &#60;", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :entity - {:original=>\"&#38;\", :location=>1} - code_point: 38\n     - :text - {:location=>1} - \" - \"\n     - :entity - {:original=>\"&#60;\", :location=>1} - code_point: 60\n"],
          [:span_extensions, "This is a {::comment}simple{:/} paragraph.", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is a \"\n     - :comment - {:location=>1, :category=>:span} - \"simple\"\n     - :text - {:location=>1} - \" paragraph.\"\n"],
        ].each do |parser_attrs|
          parser_name, kramdown_in, xpect = parser_attrs
          it "parses #{ parser_name }" do
            doc = Document.new(kramdown_in, { :input => 'KramdownRepositext' })
            doc.root.inspect_tree.must_equal xpect
          end
        end

      end
    end
  end
end
