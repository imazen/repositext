require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

module Kramdown
  describe TreeCleaner do

    describe 'recursively_clean_up_tree!' do

      em1 = ElementRt.new(:em, nil, 'id' => 'em1')
      em2 = ElementRt.new(:em, nil, 'id' => 'em2')
      hr = ElementRt.new(:hr)
      p1 = ElementRt.new(:p, nil, 'id' => 'p1')
      p2 = ElementRt.new(:p, nil, 'id' => 'p2')
      root = ElementRt.new(:root)
      strong1 = ElementRt.new(:strong, nil, 'id' => 'strong1')
      strong2 = ElementRt.new(:strong, nil, 'id' => 'strong2')
      text1 = ElementRt.new(:text, "text1")
      text2 = ElementRt.new(:text, "text2")
      text_b1 = ElementRt.new(:text, " ", 'id' => 'text_b1')

      [
        [
          "removes :hr's children",
          # - :p - {"id"=>"p1"}
          #   - :hr
          #     - :text - "text1"
          construct_kramdown_rt_tree(
            [p1, [
              [hr, [text1]],
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :hr
            )
        ],
        [
          "removes :em without children",
          # - :p - {"id"=>"p1"}
          #   - :em - {"id"=>"em1"}
          #     - :text - "text1"
          #   - :em - {"id"=>"em2"}
          #   - :text - "text2"
          construct_kramdown_rt_tree(
            [p1, [
              [em1, [text1]],
              em2,
              text2,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :em - {"id"=>"em1"}
                 - :text - "text1"
               - :text - "text2"
            )
        ],
        [
          "removes :strong without children",
          # - :p - {"id"=>"p1"}
          #   - :strong - {"id"=>"strong1"}
          #     - :text - "text1"
          #   - :strong - {"id"=>"strong2"}
          #   - :text - "text2"
          construct_kramdown_rt_tree(
            [p1, [
              [strong1, [text1]],
              strong2,
              text2,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :strong - {"id"=>"strong1"}
                 - :text - "text1"
               - :text - "text2"
            )
        ],
        [
          "removes :p without children",
          # - :root
          #   - :p - {"id"=>"p1"}
          #     - :text - "text1"
          #   - :p - {"id"=>"p2"}
          #   - :text - "text2"
          construct_kramdown_rt_tree(
            [root, [
              [p1, [text1]],
              p2,
              text2,
            ]]
          ),
          %( - :root
               - :p - {"id"=>"p1"}
                 - :text - "text1"
               - :text - "text2"
            )
        ],
        [
          "removes :p that contains whitespace only",
          # - :root
          #   - :p - {"id"=>"p1"}
          #     - :text - "text1"
          #   - :p - {"id"=>"p2"}
          #     - :text - {"id"=>"text_b1"} - " "
          construct_kramdown_rt_tree(
            [root, [
              [p1, [text1]],
              [p2, [text_b1]],
            ]]
          ),
          %( - :root
               - :p - {"id"=>"p1"}
                 - :text - "text1"
            )
        ],
      ].each do |desc, kt, xpect|
        it desc do
          parser = Parser::Folio.new("")
          parser.send(:recursively_clean_up_tree!, kt)
          kt.inspect_tree.must_equal xpect.gsub(/\n            /, "\n")
        end
      end

    end

    describe 'clean_up_tree_element!' do
      # This is tested via recursively_clean_up_tree!
      # I do it that way because most of the elements get deleted in this methods
      # so it's better to use the recursive method so that I get the parent element
      # back to confirm that the child is gone.
    end
  end
end
