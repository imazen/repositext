require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

describe ::Kramdown::NestedEmsProcessor do

  describe "recursively_clean_up_nested_ems!" do

    em1 = Kramdown::ElementRt.new(:em, nil, 'id' => 'em1')
    em2 = Kramdown::ElementRt.new(:em, nil, 'id' => 'em2')
    em_sc1 = Kramdown::ElementRt.new(:em, nil, 'class' => 'smcaps', 'id' => 'em_sc1')
    em_sc2 = Kramdown::ElementRt.new(:em, nil, 'class' => 'smcaps', 'id' => 'em_sc2')
    p1 = Kramdown::ElementRt.new(:p, nil, 'id' => 'p1')
    text1 = Kramdown::ElementRt.new(:text, "text1")
    text2 = Kramdown::ElementRt.new(:text, "text2")
    text3 = Kramdown::ElementRt.new(:text, "text3")
    text4 = Kramdown::ElementRt.new(:text, "text4")
    text5 = Kramdown::ElementRt.new(:text, "text5")
    text_b1 = Kramdown::ElementRt.new(:text, " ", 'id' => 'text_b1')

    [
      [
        "handles single em.smcaps inside em",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :text - "text1"
        #     - :em - {"class"=>"smcaps", "id"=>"em_sc1"}
        #       - :text - "text2"
        #     - :text - "text3"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              text1,
              [em_sc1, [text2]],
              text3,
            ]],
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - "text1"
             - :em - {"class"=>"italic smcaps", "id"=>"em_sc1"}
               - :text - "text2"
             - :em - {"id"=>"em1"}
               - :text - "text3"
          )
      ],
      [
        "handles multiple em.smcaps inside em",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :text - "text1"
        #     - :em - {"class"=>"smcaps", "id"=>"em_sc1"}
        #       - :text - "text2"
        #     - :text - "text3"
        #     - :em - {"class"=>"smcaps", "id"=>"em_sc2"}
        #       - :text - "text4"
        #     - :text - "text5"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              text1,
              [em_sc1, [text2]],
              text3,
              [em_sc2, [text4]],
              text5,
            ]],
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - "text1"
             - :em - {"class"=>"italic smcaps", "id"=>"em_sc1"}
               - :text - "text2"
             - :em - {"id"=>"em1"}
               - :text - "text3"
             - :em - {"class"=>"italic smcaps", "id"=>"em_sc2"}
               - :text - "text4"
             - :em - {"id"=>"em1"}
               - :text - "text5"
          )
      ],
    ].each do |desc, kt, xpect|
      it desc do
        parser = Kramdown::Parser::Folio.new("")
        parser.send(:recursively_clean_up_nested_ems!, kt)
        kt.inspect_tree.must_equal xpect.gsub(/\n          /, "\n")
      end
    end

  end

end
