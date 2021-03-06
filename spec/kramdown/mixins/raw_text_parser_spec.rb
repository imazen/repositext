require_relative '../../helper'

module Kramdown
  describe RawTextParser do

    describe '#process_and_add_text' do
      para_with_text_el = ElementRt.new(:p)
      para_with_text_el.children << ElementRt.new(:text, 'existing text node ')
      [
        [
          "multibyte char \u00A0",
          ElementRt.new(:p),
          %( - :p
               - :text - \"multibyte char \"
               - :entity - {:original=>\"&#x00A0;\"} - code_point: 160
            )
        ],
        [
          "multibyte char \u2011",
          ElementRt.new(:p),
          %( - :p\n   - :text - \"multibyte char \"\n   - :entity - {:original=>\"&#x2011;\"} - code_point: 8209\n)
        ],
        [
          "multibyte char \u2028",
          ElementRt.new(:p),
          %( - :p\n   - :text - \"multibyte char \"\n   - :entity - {:original=>\"&#x2028;\"} - code_point: 8232\n)
        ],
        [
          "multibyte char \u202F",
          ElementRt.new(:p),
          %( - :p\n   - :text - \"multibyte char \"\n   - :entity - {:original=>\"&#x202F;\"} - code_point: 8239\n)
        ],
        [
          "multibyte char \uFEFF",
          ElementRt.new(:p),
          %( - :p\n   - :text - \"multibyte char \"\n   - :entity - {:original=>\"&#xFEFF;\"} - code_point: 65279\n)
        ],
        [ # empty string
          "",
          ElementRt.new(:p),
          %( - :p\n)
        ],
        [
          "with additional text",
          para_with_text_el,
          %( - :p\n   - :text - \"existing text node with additional text\"\n)
        ],
        [
          "with location",
          ElementRt.new(:p, nil, nil, { :location => 42 }),
          %( - :p - {:location=>42}\n   - :text - {:location=>42} - \"with location\"\n)
        ],
        [
          "invalid multibyte char \u1571 ",
          ElementRt.new(:p),
          %( - :p\n   - :text - \"invalid multibyte char ᕱ \"\n)
        ],
      ].each do |test_string, tree, xpect|
        it "handles #{ test_string }" do
          p = Parser::IdmlStory.send(:new, '_', {})
          p.send(
            :process_and_add_text,
            test_string,
            tree,
            :text
          ).inspect_tree.must_equal(xpect.gsub(/\n            /, "\n"))
        end
      end
    end

  end
end
