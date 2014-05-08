require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

describe ::Kramdown::AdjacentElementMerger do

# TODO: add spec for parallel strings of mergable elements several levels deep
  describe "recursively_merge_adjacent_elements!" do

    em_a1 = Kramdown::ElementRt.new(:em, nil, 'class' => 'a', 'id' => 'em_a1')
    em_a2 = Kramdown::ElementRt.new(:em, nil, 'class' => 'a', 'id' => 'em_a2')
    em_b1 = Kramdown::ElementRt.new(:em, nil, 'class' => 'b', 'id' => 'em_b1')
    em_b2 = Kramdown::ElementRt.new(:em, nil, 'class' => 'b', 'id' => 'em_b2')
    p1 = Kramdown::ElementRt.new(:p, nil, 'id' => 'p1')
    strong_a1 = Kramdown::ElementRt.new(:strong, nil, 'class' => 'a', 'id' => 'strong_a1')
    strong_a2 = Kramdown::ElementRt.new(:strong, nil, 'class' => 'a', 'id' => 'strong_a2')
    text1 = Kramdown::ElementRt.new(:text, "text1")
    text2 = Kramdown::ElementRt.new(:text, "text2")
    text3 = Kramdown::ElementRt.new(:text, "text3")
    text4 = Kramdown::ElementRt.new(:text, "text4")
    text_b1 = Kramdown::ElementRt.new(:text, " ", 'id' => 'text_b1')

    [
      [
        "merges two adjacent ems that are of same type (and have different ids)",
        construct_kramdown_rt_tree(
          [p1, [
            [em_a1, [text1]],
            [em_a2, [text2]],
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"class"=>"a", "id"=>"em_a1"}
               - :text - "text1"
               - :text - "text2"
          )
      ],
      [
        "merges two adjacent strongs that are of same type (and have different ids)",
        construct_kramdown_rt_tree(
          [p1, [
            [strong_a1, [text1]],
            [strong_a2, [text2]],
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :strong - {"class"=>"a", "id"=>"strong_a1"}
               - :text - "text1"
               - :text - "text2"
          )
      ],
      [
        "doesn't merge adjacent ems if they are of different type",
        construct_kramdown_rt_tree(
          [p1, [
            [em_a1, [text1]],
            [em_b1, [text2]],
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"class"=>"a", "id"=>"em_a1"}
               - :text - "text1"
             - :em - {"class"=>"b", "id"=>"em_b1"}
               - :text - "text2"
          )
      ],
      [
        "merges two adjacent ems if they are separated by whitespace only",
        construct_kramdown_rt_tree(
          [p1, [
            [em_a1, [text1]],
            text_b1,
            [em_a2, [text2]],
          ]]
        ),
        %( - :p - {"id"=>"p1"}
             - :em - {"class"=>"a", "id"=>"em_a1"}
               - :text - "text1"
               - :text - {"id"=>"text_b1"} - " "
               - :text - "text2"
          )
      ],
    ].each do |desc, kt, xpect|
      it desc do
        parser = Kramdown::Parser::Folio.new("")
        parser.send(:recursively_merge_adjacent_elements!, kt)
        kt.inspect_tree.must_equal xpect.gsub(/\n          /, "\n")
      end
    end

  end

end
