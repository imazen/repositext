require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

describe ::Kramdown::WhitespaceOutPusher do

  describe "recursively_push_out_whitespace!" do

    em1 = Kramdown::ElementRt.new(:em, nil, 'id' => 'em1')
    em2 = Kramdown::ElementRt.new(:em, nil, 'id' => 'em2')
    p1 = Kramdown::ElementRt.new(:p, nil, 'id' => 'p1')
    strong1 = Kramdown::ElementRt.new(:strong, nil, 'id' => 'strong1')
    strong2 = Kramdown::ElementRt.new(:strong, nil, 'id' => 'strong2')
    text1 = Kramdown::ElementRt.new(:text, "text1")
    text2 = Kramdown::ElementRt.new(:text, "text2")
    text3 = Kramdown::ElementRt.new(:text, "text3")
    text4 = Kramdown::ElementRt.new(:text, "text4")
    text_w_leading_space = Kramdown::ElementRt.new(:text, " leading")
    text_w_trailing_space = Kramdown::ElementRt.new(:text, "trailing ")
    # TODO: write specs that use these:
    leading_tab = Kramdown::ElementRt.new(:text, "\tleading")
    trailing_tab = Kramdown::ElementRt.new(:text, "trailin\t")
    leading_nl = Kramdown::ElementRt.new(:text, "\nleading")
    trailing_nl = Kramdown::ElementRt.new(:text, "trailing\n")
    leading_dbl_space = Kramdown::ElementRt.new(:text, "  leading")

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
    ].each do |desc, kt, xpect|
      it desc do
        parser = Kramdown::Parser::Folio.new("")
        parser.send(:recursively_push_out_whitespace!, kt)
        kt.inspect_tree.must_equal xpect.gsub(/\n          /, "\n")
      end
    end

  end

end
