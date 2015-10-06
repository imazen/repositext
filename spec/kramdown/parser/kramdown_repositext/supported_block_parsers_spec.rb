require_relative '../../../helper'

module Kramdown
  module Parser
    describe KramdownRepositext do

      describe 'Supported block parsers' do

        [
          [:atx_header, "# header", %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :header - {:level=>1, :raw_text=>\"header\", :location=>1}\n     - :text - {:location=>1} - \"header\"\n)],
          [:blank_line, "\n\n\n", %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :blank - {:location=>4} - \"\\n\\n\\n\"\n)],
          [:block_extensions, "{::comment}\nThis is a comment {:/}which is {:/comment} ignored.\n{:/comment}", %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :comment - {:location=>1, :category=>:block} - \"This is a comment {:/}which is {:/comment} ignored.\"\n)],
          [:record_mark, "^^^", %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :record_mark - {:category=>:block, :location=>1}\n)],
          [:horizontal_rule, "***", %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :hr - {:location=>1}\n)],
          [:paragraph, "This is just a normal paragraph.", %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :p - {:location=>1}\n     - :text - {:location=>1} - \"This is just a normal paragraph.\"\n)],
          [:setext_header, "header\n====", " - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :header - {:level=>1, :raw_text=>\"header\", :location=>1}\n     - :text - {:location=>1} - \"header\"\n"]
        ].each do |parser_attrs|
          parser_name, kramdown_in, xpect = parser_attrs
          it "parses #{ parser_name }" do
            doc = Kramdown::Document.new(kramdown_in, { :input => 'KramdownRepositext' })
            doc.root.inspect_tree.must_equal xpect
          end
        end

        it "parses record_mark attributes" do
        end

        describe "record ids starting with numbers" do
          it "doesn't handle record_mark ids starting with numbers" do
            doc = Kramdown::Document.new("^^^{:.rid #123abc}", { :input => 'KramdownRepositext' })
            doc.root.inspect_tree.must_equal %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :record_mark - {\"class\"=>\"rid\"} - {:category=>:block, :location=>1, :ial=>{\"class\"=>\"rid\"}}\n)
          end

          it "handles record_mark ids that don't start with numbers" do
            doc = Kramdown::Document.new("^^^{:.rid #rid-123abc}", { :input => 'KramdownRepositext' })
            doc.root.inspect_tree.must_equal %( - :root - {:encoding=>#<Encoding:UTF-8>, :location=>1, :abbrev_defs=>{}}\n   - :record_mark - {\"class\"=>\"rid\", \"id\"=>\"rid-123abc\"} - {:category=>:block, :location=>1, :ial=>{\"class\"=>\"rid\", \"id\"=>\"rid-123abc\"}}\n)
          end
        end

      end
    end
  end
end
