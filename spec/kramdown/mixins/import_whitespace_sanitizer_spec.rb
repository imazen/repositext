require_relative '../../helper'
require_relative '../parser/folio/helper.rb'

describe ::Kramdown::ImportWhitespaceSanitizer do

  describe "recursively_sanitize_whitespace_during_import!" do

    p1 = Kramdown::ElementRt.new(:p, nil, 'id' => 'p1')
    text1 = Kramdown::ElementRt.new(:text, "text1")
    text_lt1 = Kramdown::ElementRt.new(:text, "\ttext_lt1", 'id' => 'text_lt1')
    text_ls1 = Kramdown::ElementRt.new(:text, " text_ls1", 'id' => 'text_ls1')
    text_to1 = Kramdown::ElementRt.new(:text, "\t", 'id' => 'text_to1')
    text_ts1 = Kramdown::ElementRt.new(:text, "text_ts1 ", 'id' => 'text_ts1')
    text_wr1 = Kramdown::ElementRt.new(:text, "text_wr1 \t\t   after", 'id' => 'text_wr1')
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
    ].each do |desc, kt, xpect|
      it desc do
        parser = Kramdown::Parser::Folio.new("")
        parser.send(:recursively_sanitize_whitespace_during_import!, kt)
        kt.inspect_tree.must_equal xpect.gsub(/\n          /, "\n")
      end
    end

  end

end
