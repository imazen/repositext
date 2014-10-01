require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

module Kramdown
  describe ImportWhitespaceSanitizer do

    describe "recursively_sanitize_whitespace_during_import!" do

      p1 = ElementRt.new(:p, nil, 'id' => 'p1')
      text1 = ElementRt.new(:text, "text1")
      text_lt1 = ElementRt.new(:text, "\ttext_lt1", 'id' => 'text_lt1') # leading tab
      text_ls1 = ElementRt.new(:text, " text_ls1", 'id' => 'text_ls1') # leading space
      text_so1 = ElementRt.new(:text, " ", 'id' => 'text_so1') # space only
      text_to1 = ElementRt.new(:text, "\t", 'id' => 'text_to1') # tab only
      text_ts1 = ElementRt.new(:text, "text_ts1 ", 'id' => 'text_ts1') # trailing space
      text_wr1 = ElementRt.new(:text, "text_wr1 \t\t   after", 'id' => 'text_wr1') # with runs of whitespace
      [
        [
          "replaces an internal tab with a space",
          construct_kramdown_rt_tree(
            [p1, [
              text1,
              text_lt1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - "text1"
               - :text - {"id"=>"text_lt1"} - " text_lt1"
            )
        ],
        [
          "removes a tab that is the first text character inside a para",
          construct_kramdown_rt_tree(
            [p1, [
              text_lt1,
              text1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - {"id"=>"text_lt1"} - "text_lt1"
               - :text - "text1"
            )
        ],
        [
          "removes a space that is the first text character inside a para",
          construct_kramdown_rt_tree(
            [p1, [
              text_ls1,
              text1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - {"id"=>"text_ls1"} - "text_ls1"
               - :text - "text1"
            )
        ],
        [
          "removes a space that is the last text character inside a para",
          construct_kramdown_rt_tree(
            [p1, [
              text1,
              text_ts1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - "text1"
               - :text - {"id"=>"text_ts1"} - "text_ts1"
            )
        ],
        [
          "removes a tab and its parent if tab is first text character inside a p, and the only content",
          construct_kramdown_rt_tree(
            [p1, [
              text_to1,
              text1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - "text1"
            )
        ],
        [
          "removes a tab and its parent if tab is last text character inside a p, and the only content",
          construct_kramdown_rt_tree(
            [p1, [
              text1,
              text_to1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - "text1"
            )
        ],
        [
          "reduces runs of whitespace to single space",
          construct_kramdown_rt_tree(
            [p1, [
              text_wr1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - {"id"=>"text_wr1"} - "text_wr1 after"
            )
        ],
        [
          "removes leading whitespace in text node after space only text node first child",
          construct_kramdown_rt_tree(
            [p1, [
              text_so1,
              text_ls1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - {"id"=>"text_ls1"} - "text_ls1"
            )
        ],
        [
          "removes trailing whitespace in text node before space only text node last child",
          construct_kramdown_rt_tree(
            [p1, [
              text_ts1,
              text_so1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - {"id"=>"text_ts1"} - "text_ts1"
            )
        ],
        [
          "removes multiple space only first children",
          construct_kramdown_rt_tree(
            [p1, [
              text_so1,
              text_so1,
              text1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - "text1"
            )
        ],
        [
          "removes multiple space only last children",
          construct_kramdown_rt_tree(
            [p1, [
              text1,
              text_so1,
              text_so1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - "text1"
            )
        ],
      ].each do |desc, kt, xpect|
        it desc do
          parser = Parser::Folio.new("")
          parser.send(:recursively_sanitize_whitespace_during_import!, kt)
          kt.inspect_tree.must_equal xpect.gsub(/\n            /, "\n")
        end
      end

    end

  end
end
