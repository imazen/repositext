require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

describe ::Kramdown::TmpEmClassProcessor do

  describe 'process_temp_em_class!' do

    em1 = Kramdown::ElementRt.new(:em, nil, 'id' => 'em1')
    em2 = Kramdown::ElementRt.new(:em, nil, 'id' => 'em2')
    em_t1 = Kramdown::ElementRt.new(:em, nil, 'class' => 'tmpNoItalics', 'id' => 'em_t1')
    em_t2 = Kramdown::ElementRt.new(:em, nil, 'class' => 'tmpNoItalics', 'id' => 'em_t2')
    em_t3 = Kramdown::ElementRt.new(:em, nil, 'class' => 'tmpNoItalics', 'id' => 'em_t3')
    p1 = Kramdown::ElementRt.new(:p, nil, 'id' => 'p1')
    text1 = Kramdown::ElementRt.new(:text, "text1")
    text2 = Kramdown::ElementRt.new(:text, "text2")
    text3 = Kramdown::ElementRt.new(:text, "text3")
    text4 = Kramdown::ElementRt.new(:text, "text4")
    text5 = Kramdown::ElementRt.new(:text, "text5")
    text6 = Kramdown::ElementRt.new(:text, "text6")
    text_b1 = Kramdown::ElementRt.new(:text, " ", 'id' => 'text_b1')

    [
      [
        "handles single non-nested tmp",
        # - :p - {"id"=>"p1"}
        #   - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #     - :text - "text1"
        construct_kramdown_rt_tree(
          [p1, [
            [em_t1, [text1]],
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :text - "text1"
          )
      ],
      [
        "handles single nested tmp",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #       - :text - "text1"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              [em_t1, [text1]],
            ]]
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :text - "text1"
          )
      ],
      [
        "handles single nested tmp without children",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #     - :text - "text1"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              em_t1,
              text1,
            ]]
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - "text1"
          )
      ],
      [
        "handles single non-nested tmp without children",
        # - :p - {"id"=>"p1"}
        #   - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #   - :text - "text1"
        construct_kramdown_rt_tree(
          [p1, [
            em_t1,
            text1,
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :text - "text1"
          )
      ],
      [
        "handles multiple nested children, tmp first",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #       - :text - "text1"
        #     - :text - {"id"=>"text_b1"} - " "
        #     - :text - "text2"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              [em_t1, [text1]],
              text_b1,
              text2,
            ]]
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :text - "text1"
             - :em - {"id"=>"em1"}
               - :text - {"id"=>"text_b1"} - " "
               - :text - "text2"
          )
      ],
      [
        "handles multiple nested children, tmp in the middle",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :text - "text1"
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #       - :text - "text2"
        #     - :text - "text3"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              text1,
              [em_t1, [text2]],
              text3,
            ]]
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - "text1"
             - :text - "text2"
             - :em - {"id"=>"em1"}
               - :text - "text3"
          )
      ],
      [
        "handles multiple nested children, tmp last",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :text - "text1"
        #     - :text - {"id"=>"text_b1"} - " "
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #       - :text - "text2"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              text1,
              text_b1,
              [em_t1, [text2]]
            ]]
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - "text1"
               - :text - {"id"=>"text_b1"} - " "
             - :text - "text2"
          )
      ],
      [
        "handles multiple nested tmp children",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :text - {"id"=>"text_b1"} - " "
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #       - :text - "text1"
        #     - :text - "text2"
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t2"}
        #       - :text - "text3"
        #     - :text - "text4"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              text_b1,
              [em_t1, [text1]],
              text2,
              [em_t2, [text3]],
              text4,
            ]]
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - {"id"=>"text_b1"} - " "
             - :text - "text1"
             - :em - {"id"=>"em1"}
               - :text - "text2"
             - :text - "text3"
             - :em - {"id"=>"em1"}
               - :text - "text4"
          )
      ],
      [
        "handles multiple non-nested tmp children",
        # - :p - {"id"=>"p1"}
        #   - :text - {"id"=>"text_b1"} - " "
        #   - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #     - :text - "text1"
        #   - :text - "text2"
        #   - :em - {"class"=>"tmpNoItalics", "id"=>"em_t2"}
        #     - :text - "text3"
        #   - :text - "text4"
        construct_kramdown_rt_tree(
          [p1, [
            text_b1,
            [em_t1, [text1]],
            text2,
            [em_t2, [text3]],
            text4,
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :text - {"id"=>"text_b1"} - " "
             - :text - "text1"
             - :text - "text2"
             - :text - "text3"
             - :text - "text4"
          )
      ],
      [
        "handles multiple nested and non-nested tmp children",
        # - :p - {"id"=>"p1"}
        #   - :em - {"id"=>"em1"}
        #     - :text - {"id"=>"text_b1"} - " "
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #       - :text - "text1"
        #     - :text - "text2"
        #     - :em - {"class"=>"tmpNoItalics", "id"=>"em_t2"}
        #       - :text - "text3"
        #     - :text - "text4"
        #   - :em - {"class"=>"tmpNoItalics", "id"=>"em_t3"}
        #       - :text - "text5"
        #   - :text - "text6"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              text_b1,
              [em_t1, [text1]],
              text2,
              [em_t2, [text3]],
              text4,
            ]],
            [em_t3, [text5]],
            text6,
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - {"id"=>"text_b1"} - " "
             - :text - "text1"
             - :em - {"id"=>"em1"}
               - :text - "text2"
             - :text - "text3"
             - :em - {"id"=>"em1"}
               - :text - "text4"
             - :text - "text5"
             - :text - "text6"
          )
      ],
      [
        "merges following :em sibling with cur_ke_level_el if same",
        # - :p - {"id"=>"p1"}
        #   - :text - {"id"=>"text_b1"} - " "
        #   - :em - {"class"=>"tmpNoItalics", "id"=>"em_t1"}
        #     - :text - "text1"
        #   - :text - "text2"
        #   - :em - {"class"=>"tmpNoItalics", "id"=>"em_t2"}
        #     - :text - "text3"
        #   - :text - "text4"
        construct_kramdown_rt_tree(
          [p1, [
            [em1, [
              text1,
              [em_t1, [text2]],
              [em2, [text3]],
            ]]
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"id"=>"em1"}
               - :text - "text1"
             - :text - "text2"
             - :em - {"id"=>"em1"}
               - :text - "text3"
          )
      ],
    ].each do |desc, kt, xpect|
      it desc do
        parser = Kramdown::Parser::Folio.new("")
        parser.send(:process_temp_em_class!, kt, 'tmpNoItalics')
        kt.inspect_tree.must_equal xpect.gsub(/\n          /, "\n")
      end
    end

  end

end
