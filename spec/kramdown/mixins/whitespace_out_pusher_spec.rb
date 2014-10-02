require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

module Kramdown
  describe WhitespaceOutPusher do

    describe "recursively_push_out_whitespace!" do

      em1 = ElementRt.new(:em, nil, 'id' => 'em1')
      em2 = ElementRt.new(:em, nil, 'id' => 'em2')
      p1 = ElementRt.new(:p, nil, 'id' => 'p1')
      strong1 = ElementRt.new(:strong, nil, 'id' => 'strong1')
      strong2 = ElementRt.new(:strong, nil, 'id' => 'strong2')
      text1 = ElementRt.new(:text, "text1")
      text2 = ElementRt.new(:text, "text2")
      text3 = ElementRt.new(:text, "text3")
      text4 = ElementRt.new(:text, "text4")
      text_w_leading_space = ElementRt.new(:text, " leading")
      text_w_trailing_space = ElementRt.new(:text, "trailing ")
      space_only = ElementRt.new(:text, ' ')
      # TODO: write specs that use these:
      leading_tab = ElementRt.new(:text, "\tleading")
      trailing_tab = ElementRt.new(:text, "trailin\t")
      leading_nl = ElementRt.new(:text, "\nleading")
      trailing_nl = ElementRt.new(:text, "trailing\n")
      leading_dbl_space = ElementRt.new(:text, "  leading")

      [
        [
          "adds leading whitespace to preceding :text el",
          construct_kramdown_rt_tree(
            [p1, [
              text1,
              [em1, [text_w_leading_space]],
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - "text1 "
               - :em - {"id"=>"em1"}
                 - :text - "leading"
            )
        ],
        [
          "adds leading whitespace to new :text element if it doesn't exist",
          construct_kramdown_rt_tree(
            [p1, [
              [em1, [text_w_leading_space]],
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - " "
               - :em - {"id"=>"em1"}
                 - :text - "leading"
            )
        ],
        [
          "adds trailing whitespace to following :text el",
          construct_kramdown_rt_tree(
            [p1, [
              [em1, [text_w_trailing_space]],
              text1,
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :em - {"id"=>"em1"}
                 - :text - "trailing"
               - :text - " text1"
            )
        ],
        [
          "adds trailing whitespace to new :text element if it doesn't exist",
          construct_kramdown_rt_tree(
            [p1, [
              [em1, [text_w_trailing_space]],
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :em - {"id"=>"em1"}
                 - :text - "trailing"
               - :text - " "
            )
        ],
        [
          "removes :text nodes and parent :ems if text only contains whitespace",
          construct_kramdown_rt_tree(
            [p1, [
              [em1, [space_only]],
            ]]
          ),
          %( - :p - {"id"=>"p1"}
               - :text - " "
               - :em - {"id"=>"em1"}
            )
        ],
      ].each do |desc, kt, xpect|
        it desc do
          parser = Parser::Folio.new("")
          parser.send(:recursively_push_out_whitespace!, kt)
          kt.inspect_tree.must_equal xpect.gsub(/\n            /, "\n")
        end
      end

    end

  end
end
